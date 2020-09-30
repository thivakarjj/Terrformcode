
"""
vSphere Python SDK program for listing  Datastore Cluster
"""
import argparse
import atexit
import ssl
import requests
import random
from pyVmomi import vim
from pyVmomi import vmodl
from pyVim import connect


def get_args():
    """
   Supports the command-line arguments listed below.
   """
    parser = argparse.ArgumentParser(
        description='Process args for retrieving all SDRS Clusters')

    parser.add_argument('-s', '--host',
                        required=True, action='store',
                        help='Remote host to connect to')

    parser.add_argument('-o', '--port',
                        type=int, default=443,
                        action='store', help='Port to connect on')

    parser.add_argument('-u', '--user', required=True,
                        action='store',
                        help='User name to use when connecting to host')

    parser.add_argument('-p', '--password',
                        required=True, action='store',
                        help='Password to use when connecting to host')
    args = parser.parse_args()
    return args
def get_all_objs(content, vimtype):
        obj = {}
        container = content.viewManager.CreateContainerView(content.rootFolder, vimtype, True)
        for managed_object_ref in container.view:
                obj.update({managed_object_ref: managed_object_ref.name})
        return obj
def get_SDRS_Random(Clusters):
    tmp_sdrs=[]
    for cls in Clusters:
        tmp_sdrs.append(cls.name)
    return random.choice(tmp_sdrs)
def main():
    """
   Simple command-line program for listing Datastores in Datastore Cluster
   """
    ssl._create_default_https_context = ssl._create_unverified_context
    context = ssl.create_default_context()
    context.check_hostname = False
    context.verify_mode = ssl.CERT_NONE
    requests.packages.urllib3.disable_warnings()
    args = get_args()

    try:
        service_instance = connect.SmartConnect(host=args.host,
                                                user=args.user,
                                                pwd=args.password,
                                                port=int(args.port))
        if not service_instance:
            print("Could not connect to the specified host using "
                  "specified username and password")
            return -1

        atexit.register(connect.Disconnect, service_instance)
        content = service_instance.RetrieveContent()
        datastore_Clusters = get_all_objs(content, [vim.StoragePod])
        sdrs_cluster=get_SDRS_Random(datastore_Clusters)
        print(sdrs_cluster)
    except vmodl.MethodFault as error:
        print ("Caught vmodl fault : " + error.msg)
        return -1

    return 0

# Start program
if __name__ == "__main__":
    main()
