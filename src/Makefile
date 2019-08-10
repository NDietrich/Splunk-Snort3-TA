# What is the name of the TA folder?
APPNAME=TA_Snort3_json

# where to instll the SPL file (extracted to your snort app directory)
# may need to run with elevated priviledges to install to Splunk directory
APPDIR=/home/noah/Desktop/

# Function Definitions 

# create a clone of the source folder into the build folder
define clone_src_folder
# create temp working folder
	mkdir build
	cp -r ./${APPNAME} ./build
	chmod 755 ./build/${APPNAME}
endef

# Prepare a source folder to be turned into a spl file, do NOT remove the local directory
define clean_src_folder
# remove all hidden files and folders
	find ./ -name ".*" -exec rm -rf {} \;
	
# remove any files in metadata that aren't default.meta
	rm -rf ./metadata/local.meta || true

# all files should be 644, directories should be 755
# http://dev.splunk.com/view/app-cert/SP-CAAAE3H
	find ./ -type f -exec chmod 644 {} \;
	find ./ -type d -exec chmod 755 {} \;

# get rid of all .pyc files in bin (todo, not working)
#find ./bin -type f -name '*.pyc' -delete 2>/dev/null

# remove all temp files (ending with tilde)
	find . -type f -name '*~' -exec rm -f '{}' \; 
endef

# Build SPL file
define build_SPL
# create spl file (tar.gz)
	cd ./build ; tar -zcvf ${APPNAME}.tar.gz ${APPNAME}
	mv ./build/${APPNAME}.tar.gz ${APPNAME}.spl

endef

# Default Command
spl : clean
	$(call clone_src_folder,)
	$(call clean_src_folder, )
	rm -rf ./build/${APPNAME}/local/
	$(call build_SPL, )

.PHONY : install
install : spl
	rm -rf ${APPDIR}
	tar -xzvf ${APPNAME}.spl --directory ${APPDIR}

# Create a SPL without deleting the local folder contents (for local testing)
.PHONY : local-spl
local-spl : clean
	$(call clone_src_folder,)
	$(call clean_src_folder, )
	$(call build_SPL, )

.PHONY : local-install
install-testing : local-spl
	rm -rf ${APPDIR}/${APPNAME}
	tar -xzvf ${APPNAME}.spl --directory ${APPDIR}


.PHONY : clean
clean : 
	-rm -rf ./build
	-rm -rf ${APPNAME}.spl
	-rm -rf ${APPNAME}.spl.tgz
