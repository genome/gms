TUTORIAL

(These notes are underd development and refer currently to TGI test servers.  Stay tuned for a final version usable from github.)

From your Ubuntu GMS system (either standalone hardware or with a VM if you went that route)

Install curlftpfs on my Mac to allow me to mount data from clinus234 on my Mac
% brew install curlftpfs
% sudo /bin/cp -rfX /usr/local/Cellar/fuse4x-kext/0.9.2/Library/Extensions/fuse4x.kext /Library/Extensions
% sudo chmod +s /Library/Extensions/fuse4x.kext/Support/load_fuse4x
% curlftpfs ftp://clinus234 $PWD/clinus234 -o tcp_nodelay,kernel_cache,direct_io,use_ino

Start the virtual machine
% vagrant ssh


Now mount the clinus234 data into the virtual machine at /opt/gms/GMS1
% cd /opt/gms/
% sudo ln -s ../../vagrant/clinus234 GMS1
% ls GMS1

Examine the current cluster configuration
% bjobs
% bhosts
% bqueues 

View disk groups currently defined in the system.  You should see at least 4 disk groups defined if the GMS installation worked correctly
% genome disk group list

View disk volumes known to GMS
% genome disk volume list 

Import the TST1 test metadata - this will populate the database with example models, processing profiles, instrument data, etc.
% genome model import metadata /opt/gms/GMS1/export/TST1.dat

View sample currently in the database
% genome sample list

View libraries for these samples currently in the database
% genome library list

View models currently in the database
% genome model list

View processing profiles of type 'somatic-variation' currently in the database
% genome processing-profile list somatic-variation

Describe one of these processing profiles by specifying the ID
% genome processing-profile describe --processing-profiles=2762562

Launch builds for the microarray models corresponding to the tumor and normal genomic DNA samples
% genome model build start 2891230328 
% genome model build start 2891230330
 
Check the 'cluster' queue to see the status of running jobs
% bjobs

Ask GMS the status of builds for these models
% genome model build view model.id=2891230328
% genome model build view model.id=2891230330



