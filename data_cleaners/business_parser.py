import os
import json
import csv


yelp_data_folder = 'path/to/yelp/dataset/folder/'
business_json = 'business.json'

class BusinessModel:
    def __init__(self, business_details):
        self.business_yelp_details = business_details

    def toDict(self):
        business_dict = dict()

        business_dict['business_id'] = self.business_yelp_details.get('business_id', None)
        business_dict['name'] = self.business_yelp_details.get('name', None)
        business_dict['address'] = self.business_yelp_details.get('address', None)
        business_dict['city'] = self.business_yelp_details.get('city', None)
        business_dict['state'] = self.business_yelp_details.get('state', None)
        business_dict['postal_code'] = self.business_yelp_details.get('postal_code', None)
        business_dict['latitude'] = self.business_yelp_details.get('latitude', None)
        business_dict['longitude'] = self.business_yelp_details.get('longitude', None)
        business_dict['stars'] = self.business_yelp_details.get('stars', None)
        business_dict['review_count'] = self.business_yelp_details.get('review_count', None)
        business_dict['RestaurantsTableService'] = self.business_yelp_details.get('RestaurantsTableService', None)
        business_dict['RestaurantsTakeOut'] = self.business_yelp_details.get('RestaurantsTakeOut', None)
        business_dict['RestaurantsPriceRange2'] = self.business_yelp_details.get('RestaurantsPriceRange2', None)

        return business_dict


class BusinessParser:
    def __init__(self):
        self.business_json = os.path.join(yelp_data_folder, business_json)

    def parse(self):
        business_dicts = list()
        with open(self.business_json, 'r') as bj:
            line = bj.readline()
            line_count =1
            while line:
                business_obj = json.loads(line)
                business_dicts.append(BusinessModel(business_obj).toDict())
                line_count +=1
                line = bj.readline()
                print("{} lines processes".format(line_count))
        print("Parsed {} lines".format(line_count))
        return business_dicts


def save_to_json(file_path, obj):
    with open(file_path, 'w') as parsed_file:
        json.dump(obj, parsed_file)


def save_to_csv(file_path, obj):
    fieldnames = obj[0].keys()
    with open(file_path, 'w') as parsed_file:
        writer = csv.DictWriter(parsed_file, fieldnames=fieldnames)
        writer.writeheader()
        for ob in obj:
            writer.writerow(ob)


if __name__ == '__main__':
    business = BusinessParser()
    parser_output = business.parse()
    print(len(parser_output))
    save_to_csv('/Users/venkatakoonaparaju/Downloads/yelp_dataset/business_parsed.csv', parser_output)

