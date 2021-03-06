require "interactive_brokers_2_tasty_works/version"

require 'csv'
require 'json'
require 'xmlhasher'
require 'bigdecimal'
require 'active_support/core_ext/time/zones'

unless NilClass.method_defined?(:empty?)
  class NilClass
    def empty?; true; end
  end
end

class InteractiveBrokers2TastyWorks
  attr_reader :input_path, :file_format

  OUTPUT_HEADER = ['Date', 'Type', 'Action', 'Symbol', 'Instrument Type', 'Description', 'Value', 'Quantity',
                   'Average Price', 'Commissions', 'Fees', 'Multiplier', 'Underlying Symbol', 'Expiration Date',
                   'Strike Price', 'Call or Put']

  def initialize(data_hash: nil, input_path: nil, file_format: :xml, add_output: nil)
    @data_hash   = data_hash
    @input_path  = input_path
    @file_format = file_format
    @add_output  = add_output

    raise ArgumentError.new("Must specify `data_hash` or `input_path`.") if data_hash.empty? && input_path.empty?

    if !input_path.empty?
      file_format = input_path.split(".").last.to_sym if file_format.empty?
      file_format = file_format.to_s.to_sym unless file_format.is_a?(Symbol)
      raise ArgumentError.new("Unknown file format: #{file_format}") unless %i(xml json).include?(file_format)
    end
  end

  def save_as(output_path)
    File.open(File.expand_path(output_path), 'w') do |f|
      output.each { |o| f.write(o.to_csv) }
    end
  end

  def output
    @output ||= convert!
  end

  private

  def convert!
    output = [add_output_headers ? (OUTPUT_HEADER + add_output_headers) : OUTPUT_HEADER]

    trades = if data_hash[:FlexQueryResponse].is_a?(Array)
      data_hash[:FlexQueryResponse][1][:FlexStatements][1][:FlexStatement][1][:Trades][:Trade]
    else
      data_hash[:FlexQueryResponse][:FlexStatements][:FlexStatement][:Trades][:Trade]
    end

    trades.each do |trade|
      trade = trade.first if trade.is_a?(Array)

      output << [
        Utils.build_date_time_str(trade),
        'Trade',
        Utils.build_action(trade),
        trade[:symbol],
        Utils.build_instrument_type(trade),
        Utils.build_description(trade),
        Utils.build_value(trade),
        trade[:quantity],
        Utils.build_trade_price(trade),
        Utils.build_commission(trade),
        '',
        trade[:multiplier],
        trade[:underlyingSymbol],
        Utils.build_date(trade[:expiry]),
        trade[:strike],
        Utils.put_or_call(trade)
      ]

      output.last.concat(add_output_values(trade)) if add_output_values(trade)
    end
    output
  end

  def data_hash
    @data_hash ||= case @file_format
    when :json
      file = File.read(File.expand_path(@input_path))
      JSON.parse(file, symbolize_names: true)
    when :xml
      XmlHasher::Parser.new(
        :snakecase => false,
        :ignore_namespaces => true,
        :string_keys => false
      ).parse(File.new(@input_path))
    end
  end

  def add_output_values(trade)
    return nil unless @add_output.present?
    add_output_fields.map { |f| Utils.indifferent_fetch(trade, f) }
  end

  def add_output_fields
    if @add_output.is_a?(Hash)
      @add_output.keys
    elsif @add_output.is_a?(Array)
      @add_output
    end
  end

  def add_output_headers
    if @add_output.is_a?(Hash)
      @add_output.values
    elsif @add_output.is_a?(Array)
      @add_output
    end
  end

  module Utils
    class << self
      def build_date_time_str(trade)
        d, t = trade[:tradeDate], trade[:tradeTime]
        year = d[0..3]
        month = d[4..5]
        day = d[6..7]
        hour = t[0..1]
        min = t[2..3]
        sec = t[4..5]
        Time.zone.local(year,month,day,hour,min,sec).strftime('%FT%T%z')
      end

      def build_date(str)
        return nil if str.to_s.strip == ''
        day = str[6..7]
        month = str[4..5]
        year = str[2..3]
        "#{month}/#{day}/#{year}"
      end

      def build_action(trade)
        "#{trade[:buySell]}_TO_#{trade[:openCloseIndicator] == 'O' ? 'OPEN' : 'CLOSE'}"
      end

      def build_instrument_type(trade)
        case (ac = trade[:assetCategory])
        when 'OPT'; 'Equity Option'
        when 'STK'; 'Equity'
        else
          raise ArgumentError.new("Unknown asset category: #{ac}")
        end
      end

      def build_description(trade)
        case trade[:buySell]
        when 'SELL'; str = 'Sold'
        when 'BUY'; str = 'Bought'
        end

        str += " #{trade[:quantity].to_i.abs} "

        str += case (ac = trade[:assetCategory])
        when 'OPT'
          exp = build_date(trade[:expiry])
          "#{trade[:symbol]} #{exp} #{put_or_call(trade)} #{trade[:strike]} @ #{build_trade_price(trade)}"
        when 'STK'
          "#{trade[:symbol]} @ #{build_trade_price(trade)}"
        else
          raise ArgumentError.new("Unknown asset category: #{ac}")
        end

        str
      end

      def build_trade_price(trade)
        if string_is_zero?(trade[:tradePrice]) && !string_is_zero?(build_value(trade))
          value = build_value(trade).to_f
          strip_zero_decimal (value / trade[:quantity].to_i / trade[:multiplier].to_i).abs
        else
          trade[:tradePrice]
        end
      end

      def build_value(trade)
        if !proceeds_is_zero?(trade)
          v = trade[:proceeds]
        elsif is_option_assignment_exercise_or_expiration(trade)
          v = strip_zero_decimal(trade[:mtmPnl].to_f * -1)
        else
          raise ArgumentError.new("Cannot parse trade: #{trade}")
        end

        (v.to_f == -0.0 ? 0 : v).to_s
      end

      def build_commission(trade)
        c = trade[:ibCommission]
        c.to_f == -0.0 ? '0' : c
      end

      def put_or_call(trade)
        return nil unless trade[:assetCategory] == 'OPT'
        trade[:putCall] == 'P' ? 'PUT' : 'CALL'
      end

      def string_is_zero?(str)
        str = str.to_s.strip
        str == '0' || str == '-0'
      end

      def proceeds_is_zero?(trade)
        string_is_zero?(trade[:proceeds])
      end

      def strip_zero_decimal(val)
        val.to_s.sub(/\.0$/, '')
      end

      def is_option_assignment_exercise_or_expiration(trade)
         proceeds_is_zero?(trade) && trade[:transactionType] == "BookTrade" && trade[:notes] =~ /^A$|^Ex$|^Ep$/i
      end

      def indifferent_fetch(h, key)
        h.fetch(key)
      rescue KeyError
        h[key.is_a?(String) ? key.to_sym : key.to_s]
      end
    end
  end
end
