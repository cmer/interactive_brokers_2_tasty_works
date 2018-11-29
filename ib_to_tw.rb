require 'csv'
require 'json'
require 'xmlhasher'

class NilClass
  def empty?; true; end
end

class IbToTw
  # Interactive Brokers to TastyWorks converter
  #
  # Example:
  #
  #   IbToTw.new(input_path: '~/trades.xml').save_as("/tmp/trades.csv")
  #

  attr_reader :input_path, :file_format

  OUTPUT_HEADER = ['Date', 'Type', 'Action', 'Symbol', 'Instrument Type', 'Description', 'Value', 'Quantity',
                   'Average Price', 'Commissions', 'Fees', 'Multiplier', 'Underlying Symbol', 'Expiration Date',
                   'Strike Price', 'Call or Put']

  def initialize(data_hash: nil, input_path: nil, file_format: :xml)
    @data_hash   = data_hash
    @input_path  = input_path
    @file_format = file_format

    raise ArgumenrError.new("Must specify `data_hash` or `input_path`.") if data_hash.empty? && input_path.empty?

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
    output = [OUTPUT_HEADER]

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
        trade[:tradeMoney],
        trade[:quantity],
        trade[:tradePrice],
        trade[:ibCommission],
        '',
        trade[:multiplier],
        trade[:underlyingSymbol],
        Utils.build_date(trade[:expiry]),
        trade[:strike],
        Utils.put_or_call(trade)
      ]
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
        Time.new(year,month,day,hour,min,sec).strftime('%FT%T%z')
      end

      def build_date(str)
        return '' if str.to_s.strip == ''
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
          "#{trade[:symbol]} #{exp} #{put_or_call(trade)} #{trade[:strike]} @ #{trade[:tradePrice]}"
        when 'STK'
          "#{trade[:symbol]} @ #{trade[:tradePrice]}"
        else
          raise ArgumentError.new("Unknown asset category: #{ac}")
        end

        str
      end

      def put_or_call(trade)
        return '' unless trade[:assetCategory] == 'OPT'
        trade[:putCall] == 'P' ? 'PUT' : 'CALL'
      end
    end
  end
end
