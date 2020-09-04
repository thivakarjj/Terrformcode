import requests
import json
import argparse
from requests.packages.urllib3.exceptions import InsecureRequestWarning
requests.packages.urllib3.disable_warnings(InsecureRequestWarning)
 
s=requests.Session()
s.verify=False

#Function to get Arguments

def GetArgs():
    parser = argparse.ArgumentParser(
    description='Process args for retrieving clustername')
    parser.add_argument ('-s','--host', required=True, action='store',help= ' Remote host to connect to')
    parser.add_argument ('-u','--user', required=True, action='store',help= ' Input Username (username@domain)')
    parser.add_argument ('-p','--password',required=True, action='store',help= ' Input the password')
    parser.add_argument ('-t','--tag',required=True, action='store',help= ' Input the tagname to get the cluster name')
    args=parser.parse_args()
    return args

def get_vc_session(vcip, username, password):
    s.post('https://'+vcip+'/rest/com/vmware/cis/session',auth= (username,password))
    return s
def get_tag_attached(vcip,tag_id):
    tags_attached=s.post('https://'+vcip+'/rest/com/vmware/cis/tagging/tag-association/id:'+tag_id+'?~action=list-attached-objects')
    return tags_attached
def get_alltags(vcip):
    all_tags=s.get('https://'+vcip+'/rest/com/vmware/cis/tagging/tag')
    return all_tags
def get_cluster(vcip):
    cluster=s.get('https://'+vcip+'/rest/vcenter/cluster')
    return cluster
def get_tagName(vcip,data):
    tag_name=s.get('https://'+vcip+'/rest/com/vmware/cis/tagging/tag/id:'+data)
    tag_names=json.loads(tag_name.text)
    tag_json_data=tag_names["value"]["name"]
    if tag_json_data == input_tag:
        tag_id=tag_names ["value"]["id"]
        return tag_id
    
args=GetArgs()
vcip=args.host
username=args.user
password=args.password
input_tag=args.tag
get_vc_session(vcip, username, password)
all_tags=get_alltags(vcip)
all_tags_response=json.loads(all_tags.text)
json_data=all_tags_response["value"]
for data in json_data:
    tag_id=get_tagName(vcip,data)
    if tag_id:
        break
tags_attached=get_tag_attached(vcip,tag_id)
cluster_tags_attached =json.loads(tags_attached.text)
cluster_id=cluster_tags_attached["value"]
cluster_mob_id=cluster_id[0].get("id")
clusters=get_cluster(vcip)
clusters_response=json.loads(clusters.text)
clusters_json_data=clusters_response["value"]
for cls_data in clusters_json_data:
    if cls_data.get('cluster')==cluster_mob_id:
        print(cls_data.get('name'))