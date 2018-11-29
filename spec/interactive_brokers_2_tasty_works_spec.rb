require 'active_support/core_ext/time/zones'

RSpec.describe InteractiveBrokers2TastyWorks do
  def val(trade, column)
    columns = { date: 0, type: 1, action: 2, symbol: 3, instrument_type: 4, description: 5, value: 6, qty: 7, avg_price: 8,
                commissions: 9, fees: 10, multiplier: 11, underlying: 12, expiration: 13, strike: 14, put_call: 15 }

    raise ArgumentError.new("Unknown column type #{column}") unless columns.keys.include?(column)

    trade[columns[column]]
  end

  before(:all) { Time.zone = "Eastern Time (US & Canada)" }

  let(:input_file_xml) { File.join(File.expand_path(File.dirname(__FILE__)), 'samples/trades.xml').to_s }

  it "has a version number" do
    expect(InteractiveBrokers2TastyWorks::VERSION).not_to be nil
  end

  it 'converts an input xml file as it should' do
    ib2tw = InteractiveBrokers2TastyWorks.new(input_path: input_file_xml)
    output = ib2tw.output

    # expect(output.size).to eq(47)        # 46 trades + 1 header line
    expect(output.first.size).to eq(16)  # 16 columns
    expect(output.last.size).to eq(16)   # 16 columns

    expect(output.first).to eq InteractiveBrokers2TastyWorks::OUTPUT_HEADER

    trade = output[1]
    expect(val(trade, :date)).to eq "2018-11-16T16:20:00-0500"
    expect(val(trade, :type)).to eq "Trade"
    expect(val(trade, :action)).to eq "SELL_TO_CLOSE"
    expect(val(trade, :symbol)).to eq "IAG"
    expect(val(trade, :instrument_type)).to eq "Equity"
    expect(val(trade, :description)).to eq "Sold 900 IAG @ 46"
    expect(val(trade, :value)).to eq "41400"
    expect(val(trade, :qty)).to eq "-900"
    expect(val(trade, :avg_price)).to eq "46"
    expect(val(trade, :commissions)).to eq "0"
    expect(val(trade, :fees)).to eq ""
    expect(val(trade, :multiplier)).to eq "1"
    expect(val(trade, :underlying)).to be_nil
    expect(val(trade, :expiration)).to be_nil
    expect(val(trade, :strike)).to be_nil
    expect(val(trade, :put_call)).to be_nil

    trade = output[2]
    expect(val(trade, :date)).to eq "2018-11-21T09:28:08-0500"
    expect(val(trade, :type)).to eq "Trade"
    expect(val(trade, :action)).to eq "BUY_TO_OPEN"
    expect(val(trade, :symbol)).to eq "AAPL"
    expect(val(trade, :instrument_type)).to eq "Equity"
    expect(val(trade, :description)).to eq "Bought 100 AAPL @ 179.59"
    expect(val(trade, :value)).to eq "-17959"
    expect(val(trade, :qty)).to eq "100"
    expect(val(trade, :avg_price)).to eq "179.59"
    expect(val(trade, :commissions)).to eq "-1"
    expect(val(trade, :fees)).to eq ""
    expect(val(trade, :multiplier)).to eq "1"
    expect(val(trade, :underlying)).to be_nil
    expect(val(trade, :expiration)).to be_nil
    expect(val(trade, :strike)).to be_nil
    expect(val(trade, :put_call)).to be_nil

    trade = output[3]
    expect(val(trade, :date)).to eq "2018-10-25T10:12:40-0400"
    expect(val(trade, :type)).to eq "Trade"
    expect(val(trade, :action)).to eq "SELL_TO_OPEN"
    expect(val(trade, :symbol)).to eq "IAG   181116C00046000"
    expect(val(trade, :instrument_type)).to eq "Equity Option"
    expect(val(trade, :description)).to eq "Sold 9 IAG   181116C00046000 11/16/18 CALL 46 @ 1.5"
    expect(val(trade, :value)).to eq "1350"
    expect(val(trade, :qty)).to eq "-9"
    expect(val(trade, :avg_price)).to eq "1.5"
    expect(val(trade, :commissions)).to eq "-11.25"
    expect(val(trade, :fees)).to eq ""
    expect(val(trade, :multiplier)).to eq "100"
    expect(val(trade, :underlying)).to eq 'IAG'
    expect(val(trade, :expiration)).to eq '11/16/18'
    expect(val(trade, :strike)).to eq '46'
    expect(val(trade, :put_call)).to eq 'CALL'

    trade = output[6]
    expect(val(trade, :date)).to eq "2018-09-10T15:37:03-0400"
    expect(val(trade, :type)).to eq "Trade"
    expect(val(trade, :action)).to eq "SELL_TO_OPEN"
    expect(val(trade, :symbol)).to eq "ULTA  181019P00250000"
    expect(val(trade, :instrument_type)).to eq "Equity Option"
    expect(val(trade, :description)).to eq "Sold 1 ULTA  181019P00250000 10/19/18 PUT 250 @ 1.27"
    expect(val(trade, :value)).to eq "127"
    expect(val(trade, :qty)).to eq "-1"
    expect(val(trade, :avg_price)).to eq "1.27"
    expect(val(trade, :commissions)).to eq "0.012049" # commissions refund? odd.
    expect(val(trade, :fees)).to eq ""
    expect(val(trade, :multiplier)).to eq "100"
    expect(val(trade, :underlying)).to eq 'ULTA'
    expect(val(trade, :expiration)).to eq '10/19/18'
    expect(val(trade, :strike)).to eq '250'
    expect(val(trade, :put_call)).to eq 'PUT'

    trade = output[7]
    expect(val(trade, :date)).to eq "2018-10-19T16:20:00-0400"
    expect(val(trade, :type)).to eq "Trade"
    expect(val(trade, :action)).to eq "BUY_TO_CLOSE"
    expect(val(trade, :symbol)).to eq "ULTA  181019P00250000"
    expect(val(trade, :instrument_type)).to eq "Equity Option"
    expect(val(trade, :description)).to eq "Bought 45 ULTA  181019P00250000 10/19/18 PUT 250 @ 0"
    expect(val(trade, :value)).to eq "0"
    expect(val(trade, :qty)).to eq "45"
    expect(val(trade, :avg_price)).to eq "0"
    expect(val(trade, :commissions)).to eq "0"
    expect(val(trade, :fees)).to eq ""
    expect(val(trade, :multiplier)).to eq "100"
    expect(val(trade, :underlying)).to eq 'ULTA'
    expect(val(trade, :expiration)).to eq '10/19/18'
    expect(val(trade, :strike)).to eq '250'
    expect(val(trade, :put_call)).to eq 'PUT'
  end
end
