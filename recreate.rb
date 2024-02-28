require 'json'
require 'easypost'
require 'open-uri'

Dir.chdir "./RubyScripts";

file = File.read('./misc.JSON');

client = EasyPost::Client.new(api_key: ENV['EASYPOST_TEST_KEY']);

data_hash = JSON.parse(file);

properties = Array["created_at", "messages", "status", "tracking_code", "updated_at",
"batch_id", "batch_status", "batch_message", "id", "order_id",
"postage_label", "tracker", "selected_rate", "scan_form", "usps_zone",
"refund_status", "mode", "fees", "object", "rates", "insurance", "forms", "verifications"];

obj = Array[data_hash["to_address"], data_hash["from_address"], data_hash["return_address"], data_hash["buyer_address"], data_hash["parcel"]]

properties.each do |i|
  data_hash.delete(i);
end;

obj.each do |i|
    properties.each do |j|
        i.delete(j);
    end;
end

if data_hash["customs_info"] != nil
    properties.each do |i|
        data_hash["customs_info"].delete(i);
      end;
      data_hash["customs_info"]["customs_items"].each do |i|
        properties.each do |j|
            i.delete(j);
        end;
      end;
end;

if data_hash["options"]["print_custom"]
    data_hash["options"].delete("print_custom");
end;

puts "Press 1 for Rate/Buy Flow, Press 2 For One-Call-Buy";
user = gets.chomp
begin
loop do
    #Rate/Buy Flow
    if user == "1"
        shipment = client.shipment.create(
            to_address: data_hash["to_address"],
            from_address: data_hash["from_address"],
            return_address: data_hash["return_address"],
            parcel: data_hash["parcel"],
            customs_info: data_hash["customs_info"],
            options: data_hash["options"],
            reference: data_hash["reference"],
            is_return: data_hash["is_return"], 
            #carrier_accounts: [""]
            );
        if(shipment["messages"].length > 0)
            shipment["messages"].each do |i|
                puts i["carrier"];
                puts i["message"];
                puts "\n--------------------------------------------\n\n";
            end;
        end;
        if(shipment["rates"].length > 0)
            shipment["rates"].each do |i|
                puts i["carrier"] + " | " + i["carrier_account_id"];
                puts i["service"] + " | " + i["rate"];
                puts i["id"];
                puts "\n--------------------------------------------\n\n";
            end;
        elsif(shipment["rates"].length == 0)
            break;
        end;
        puts shipment["id"];

        puts "\nPlease enter the rate you wish to purchase(or, press enter to quit): ";
        user = gets.chomp
        if user.match(/rate_/)
            purchased = client.shipment.buy(shipment["id"], rate: {id: user});
            #Any data you wish to display or open to.
            system("open #{purchased["postage_label"]["label_url"]}");
        else
            #Any data you wish to display or open to.
            break;
        end;
        break;
    #One Call Buy
    elsif user == "2"
        shipment = client.shipment.create(
            to_address: data_hash["to_address"],
            from_address: data_hash["from_address"],
            return_address: data_hash["return_address"],
            parcel: data_hash["parcel"],
            customs_info: data_hash["customs_info"],
            options: data_hash["options"],
            reference: data_hash["reference"],
            is_return: data_hash["is_return"],
            carrier_accounts: [""],
            service: "yadda yadda yadda");
            #Any data you wish to display or open to.
            system("open #{shipment["postage_label"]["label_url"]}");
            break;
    end;
end;
rescue EasyPost::Errors::ApiError => e
    puts "#{e.code}: #{e.message}";
  end;