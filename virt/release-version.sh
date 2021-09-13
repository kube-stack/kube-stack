#!/usr/bin/env bash

##############################init###############################################
if [ ! -n "$1" ] ;then
    echo "error: please input a release version number!"
    echo "Usage $0 <version number>"
    exit 1
else
    if [[ "$1" =~ ^[A-Za-z0-9.]*$ ]] ;then
        echo -e "\033[3;30;47m*** Build a new release version: \033[5;36;47m($1)\033[0m)"
        echo -e "Institute of Software, Chinese Academy of Sciences"
        echo -e "        wuyuewen@otcaix.iscas.ac.cn"
        echo -e "              Copyright (2021)\n"
    else
        echo "error: wrong syntax in release version number, support chars=[A-Za-z0-9.]"
        exit 1
    fi
fi

VERSION=$1

echo -e "\033[3;30;47m*** Pull latest version from Github.\033[0m"
git pull
if [ $? -ne 0 ]; then
    echo "    Failed to pull latest version from Github!"
    exit 1
else
    echo "    Success pull latest version."
fi

##############################patch stuff#########################################
SHELL_FOLDER=$(dirname $(readlink -f "$0"))
cd ${SHELL_FOLDER}
if [ ! -d "./dist" ]; then
	mkdir ./dist
fi
#cp -f ../OVN/src/kubeovn-adm ./
#chmod +x kubeovn-adm
#gzexe ./kubeovn-adm
#cp -f kubeovn-adm ./dist
#gzexe -d ./kubeovn-adm
#rm -f ./kubeovn-adm~ ./kubeovn-adm
gzexe ./core/plugins/device-passthrough
cp -f ./core/plugins/device-passthrough ./dist
gzexe -d ./core/plugins/device-passthrough
rm -f ./core/plugins/device-passthrough~
# gzexe ../scripts/kubevirt-ctl
# cp -f ../scripts/kubevirt-ctl ./dist
# gzexe -d ../scripts/kubevirt-ctl
# rm -f ../scripts/kubevirt-ctl~
#cp -f ./core/plugins/ovn-ovsdb.service ./dist
cp -f ./core/utils/arraylist.cfg ./dist
cp -rf ./yamls ./dist
cp -rf ./monitor ./dist
echo ${VERSION} > ./VERSION
cd ./core/plugins
pyinstaller -F kubevmm_adm.py -n kubevmm-adm
if [ $? -ne 0 ]; then
    echo "    Failed to compile <kubevmm-adm>!"
    exit 1
else
    echo "    Success compile <kubevmm-adm>."
fi
cp -f ./dist/kubevmm-adm ../../dist
cp -f virshplus.py ../
cd ..
pyinstaller -F virshplus.py
if [ $? -ne 0 ]; then
    echo "    Failed to compile <virshplus>!"
    exit 1
else
    echo "    Success compile <virshplus>."
fi
cp -f ./dist/virshplus ../dist
rm -f virshplus.py
rm -rf ./dist
cd ..
#cp -rf ../SDS ./
#cd ./SDS

#pyinstaller -F kubesds-adm.py
#if [ $? -ne 0 ]; then
    #    echo "    Failed to compile <kubesds-adm>!"
    #exit 1
#else
    #    echo "    Success compile <kubesds-adm>."
#fi
#pyinstaller -F kubesds-rpc-service.py
#if [ $? -ne 0 ]; then
    #    echo "    Failed to compile <kubesds-rpc>!"
    #exit 1
#else
    #    echo "    Success compile <kubesds-rpc>."
#fi
#cp -f ./kubesds-ctl.sh ../docker/virtctl
#cp -f ./kubesds-ctl.sh ../dist
#cp -f ./kubesds.service ../dist
#cp -f ./dist/kubesds-adm ../docker/virtctl
#cp -f ./dist/kubesds-adm ../dist
#cp -f ./dist/kubesds-rpc-service ../docker/virtctl
#cp -f ./dist/kubesds-rpc-service ../dist
#cd ..
#rm -rf ./SDS

find ${SHELL_FOLDER}/dist -maxdepth 1 -type f -exec ln -s {} $HOME/rpmbuild/SOURCES/ \;
find ${SHELL_FOLDER}/dist -type d -exec ln -s {} $HOME/rpmbuild/SOURCES/ \;

#cp -rf ./dist/yamls/ ./VERSION ./dist/arraylist.cfg ./dist/virshplus ./dist/kubevmm-adm ./dist/kubeovn-adm ./dist/device-passthrough ./dist/virt-monitor ./dist/monitor docker/virtctl
cp -rf ./dist/yamls/ ./VERSION ./dist/arraylist.cfg ./dist/virshplus ./dist/kubevmm-adm ./dist/device-passthrough ./dist/monitor docker/virtctl
cp -rf ./dist/arraylist.cfg docker/virtlet
cp -rf ./dist/arraylist.cfg docker/libvirtwatcher
if [ $? -ne 0 ]; then
    echo "    Failed to copy stuff to docker/virtctl!"
    exit 1
else
    echo "    Success copy stuff to docker/virtctl."
fi

##############################patch image#########################################

# step 1 copy file
cd ./core
if [ ! -d "../docker/virtctl/utils" ]; then
	mkdir ../docker/virtctl/utils
fi
if [ ! -d "../docker/virtlet/utils" ]; then
	mkdir ../docker/virtlet/utils
fi
if [ ! -d "../docker/libvirtwatcher/utils" ]; then
	mkdir ../docker/libvirtwatcher/utils
fi
if [ ! -d "./docker/virtmonitor/utils" ]; then
	mkdir ./docker/virtmonitor/utils
fi
cp -rf utils/*.py ../docker/virtctl/utils/
cp -rf utils/*.py ../docker/virtlet/utils/
cp -rf utils/*.py ../docker/libvirtwatcher/utils/
cp -rf utils/*.py ../docker/virtmonitor/utils/
cp -rf virtctl/ ../docker/virtctl
cp -rf virtlet/ ../docker/virtlet
cp -rf libvirtwatcher/ ../docker/libvirtwatcher
cp -rf virtmonitor/ ../docker/virtmonitor
cd ..
#cd ./core
#if [ ! -d "./compile" ]; then
#	mkdir ./compile
#fi
#cp -rf utils/ virtctl/ virtlet/ ./compile
#cd ./compile
#find ./ -name *.py | xargs python3 -m py_compile
#find ./ -name *.py | xargs rm -f
#cp -f virtctl/__pycache__/virtctl.*.pyc virtctl/virtctl.pyc
#cp -f virtctl/__pycache__/virtctl_in_docker.*.pyc virtctl/virtctl_in_docker.pyc
#cp -f virtlet/__pycache__/virtlet.*.pyc virtlet/virtlet.pyc
#cp -f virtlet/__pycache__/virtlet_in_docker.*.pyc virtlet/virtlet_in_docker.pyc
#cp -rf virtctl/ utils/ ../../docker/virtctl
#cp -rf virtlet/ utils/ ../../docker/virtlet
#cd ..
#rm -rf ./compile
#cd ..

#step 2 docker build
cd docker
docker build base -t registry.cn-hangzhou.aliyuncs.com/cloudplus-lab/kubernetes-kvm-base:latest
docker build virtlet -t registry.cn-hangzhou.aliyuncs.com/cloudplus-lab/kubernetes-kvm-virtlet:${VERSION}
docker build virtctl -t registry.cn-hangzhou.aliyuncs.com/cloudplus-lab/kubernetes-kvm-virtctl:${VERSION}
docker build libvirtwatcher -t registry.cn-hangzhou.aliyuncs.com/cloudplus-lab/kubernetes-kvm-libvirtwatcher:${VERSION}
docker build virtmonitor -t registry.cn-hangzhou.aliyuncs.com/cloudplus-lab/kubernetes-kvm-virtmonitor:${VERSION}

#step 3 docker push
echo -e "\033[3;30;47m*** Login docker image repository in aliyun.\033[0m"
echo "Username: bigtree0613@126.com"
docker login --username=bigtree0613@126.com registry.cn-hangzhou.aliyuncs.com
if [ $? -ne 0 ]; then
    echo "    Failed to login aliyun repository!"
    exit 1
else
    echo "    Success login...Pushing images!"
fi
docker push registry.cn-hangzhou.aliyuncs.com/cloudplus-lab/kubernetes-kvm-base:latest
docker push registry.cn-hangzhou.aliyuncs.com/cloudplus-lab/kubernetes-kvm-virtctl:${VERSION}
docker push registry.cn-hangzhou.aliyuncs.com/cloudplus-lab/kubernetes-kvm-virtlet:${VERSION}
docker push registry.cn-hangzhou.aliyuncs.com/cloudplus-lab/kubernetes-kvm-libvirtwatcher:${VERSION}
docker push registry.cn-hangzhou.aliyuncs.com/cloudplus-lab/kubernetes-kvm-virtmonitor:${VERSION}

###############################patch version to SPECS/kubevmm.spec######################################################
echo -e "\033[3;30;47m*** Patch release version number to SPECS/kubevmm.spec\033[0m"
cd ..
sed "4s/.*/%define         _verstr      ${VERSION}/" SPECS/kubevmm.spec > SPECS/kubevmm.spec.new
mv SPECS/kubevmm.spec.new SPECS/kubevmm.spec
if [ $? -ne 0 ]; then
    echo "    Failed to patch version number to SPECS/kubevmm.spec!"
    exit 1
else
    echo "    Success patch version number to SPECS/kubevmm.spec."
fi

echo -e "\033[3;30;47m*** Push new SPECS/kubevmm.spec to Github.\033[0m"
git add ./SPECS/kubevmm.spec
# git add ./kubeovn-adm
git commit -m "new release version ${VERSION}"
git push
if [ $? -ne 0 ]; then
    echo "    Failed to push SPECS/kubevmm.spec to Github!"
    exit 1
else
    echo "    Success push SPECS/kubevmm.spec to Github."
fi

