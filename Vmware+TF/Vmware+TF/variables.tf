#@title Default title text
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
    parser.add_argument('-d', '--dc', required=True,
                        action='store',
                        help='Please input the DC Name')

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
    dc01=["vc01","vc02"]
    dc02=["vc03","vc04"]
    dc03=["vc05","vc06"]
    if(args.dc=="dc01"):
      vCenters=dc01
    elif(args.dc=="dc02"):
      vCenters=dc02
    elif(args.dc=="dc03"):
      vCenters=dc03
    else:
      print("invalid input")
      
    global_ds_names={}
    for vc in vCenters:
        print(vc)
        try:
         service_instance = connect.SmartConnect(host=vc,
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
         for ds_cluster in ds_cluster_list:
             datastores=ds_cluster.childEntity
              for datastore in datastores:
                if(datastore.summary.multipleHostAccess==True):
                  summary=datastore.summary
                  ds_capacity=summary.capacity
                  ds_freespace=summary.freespace
                  ds_freespace_gb=round(((ds_freespace/1024)/1024)/1024,2)
                  print(summary.name,ds_freespace_gb)
                  tmp={summary.name:ds_freespace_gb}
                  ds_dict.update(tmp)
                else:
                  pass
                    
         sorted_ds_dict=sorted((ds_dict.items()),key=lambda x:x[1],reverse=True)
         print("sorted_ds_dict:"sorted_ds_dict)
         tmp_update={sorted_ds_dict[0][0]:sorted_ds_dict[0][1]}
         global_ds_names.update(tmp_update)
        except vmodl.MethodFault as error:
            print("Caught vmodl fault : " + error.msg)
            return -1
    sorted_global_ds_names=sorted((global_ds_names.items()),key=lambda x:x[1],reverse=True)
    print(sorted_global_ds_names[0][0])
    return 0

# Start program
if __name__ == "__main__":
    main()