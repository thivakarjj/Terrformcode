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
def get_vim_objects(content, vim_type):
    '''Get vim objects of a given type.'''
    return [item for item in content.viewManager.CreateContainerView(
        content.rootFolder, [vim_type], recursive=True
    )

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
      
    global_vc_names={}
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
         tmp_comp_dict={}
         for vm in get_vim_objects(content,vim.ComputeResource):
           memUsedMB=vm.GetResourceUsage().memUsedMB
           memCapacityMB=vm.GetResourceUsage().memCapacityMB
           memFreeMB=memCapacityMB-memUsedMB
           tmp={vm.name:memFreeMB}
           tmp_comp_dict.update(tmp)
          keymax=max(tmp_comp_dict,key=tmp_comp_dict.get)
          print(keymax)
          tmp_ds_dict={}
          for ds in get_vim_objects(content,vim.ComputeResource):
            if ds.name==keymax:
              for ds1 in ds.datastore:
                if ds1.summary.multipleHostAccess:
                  tmp_ds={ds1.name;ds1.info.freeSpace}
                  tmp_ds_dict.update(tmp_ds)
          ds_keymax=max(tmp_ds_dict,key=tmp_ds_dict.get)
          print(ds_keymax)
          tmp_vc={vc:tmp_ds_dict[ds_keymax]}
          global_vc_names.update(tmp_vc)
        except vmodl.MethodFault as error:
            print("Caught vmodl fault : " + error.msg)
            return -1
    print(global_vc_names)
    vc_keymax=max(global_vc_names,key=global_vc_names.get)
    print(vc_keymax)
    return 0

# Start program
if __name__ == "__main__":
    main()