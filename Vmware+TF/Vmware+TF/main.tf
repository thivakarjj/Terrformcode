#Author:BhanuPrakash
#reference https://code.vmware.com/home
#website:https://vexpert.dev
"""
vSphere Python SDK program for listing Datastores in Datastore Cluster
"""
import argparse
import atexit
import ssl
from pyVmomi import vim
from pyVmomi import vmodl
from pyVim import connect
sslContext=ssl.create_default_context(purpose=ssl.purpose.CLIENT_AUTH)
sslContext.verify_mode=ssl.CERT_NONE

def get_args():
    """
   Supports the command-line arguments listed below.
   """
    parser = argparse.ArgumentParser(
        description='Reading the arguements for getting DS name')

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


def main():
    

    args = get_args()
    vCenters=["vc01","vc02"]
    try:
        service_instance = connect.SmartConnect(host=args.host,
                                                user=args.user,
                                                pwd=args.password,
                                                port=int(args.port),sslContext=sslContext)
        if not service_instance:
            print("Could not connect to the specified host using "
                  "specified username and password")
            return -1

        atexit.register(connect.Disconnect, service_instance)

        content = service_instance.RetrieveContent()
        # Search for all Datastore Clusters aka StoragePod
        obj_view = content.viewManager.CreateContainerView(content.rootFolder,
                                                           [vim.StoragePod],
                                                           True)
        ds_cluster_list = obj_view.view
        obj_view.Destroy()
        ds_dict={}
        exclude_ds_list=['dscluter1','dscluster2']
        for ds_cluster in ds_cluster_list:
          datastores=ds_cluster.childEntity
          if ds_cluster.name in exclude_ds_list:
            continue
                for datastore in datastores:
                    if(datastore.summary.multipleHostAccess==True):
                        summary=datastore.summary
                        ds_capacity=summary.capacity
                        ds_freespace=summary.freespace
                        ds_freespace_gb=round(((ds_freespace/1024)/1024)/1024,2)
                        tmp={summary.name:ds_freespace_gb}
                        ds_dict.update(tmp)
                    else:
                        print("LocalDS:{}".format(datastore.summary.name))
        sorted_ds_dict=sorted((ds_dict.items()),key=lambda x:x[1],reverse=True)
        print(next(iter(sorted_ds_dict))[0])

    except vmodl.MethodFault as error:
      print("Caught vmodl fault : " + error.msg)
      return -1

    return 0

# Start program
if __name__ == "__main__":
    main()
