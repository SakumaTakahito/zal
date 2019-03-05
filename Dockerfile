FROM centos:centos7.6.1810

RUN yum -y update && yum -y install \
    openssh-server \
    sudo \
    passwd \
    gdb-gdbserver  \
    gcc-c++ \
    gdb \
    wget \
    centos-release-scl \
    centos-release-scl-rh \
    && yum -y install devtoolset-7-gcc \
    devtoolset-7-gcc-c++ \
    devtool \
    devtoolset-7-valgrind \
    devtoolset-7-strace \
    devtoolset-7-gdb \
    devtoolset-7-gcc-gdb-plugin \
    rsync

ARG boost_version=1.64.0
ARG boost_file=boost_1_64_0
RUN cd /tmp \
    && scl enable devtoolset-7 bash \
    && wget https://dl.bintray.com/boostorg/release/${boost_version}/source/${boost_file}.tar.gz --no-check-certificate \
    && tar xfz ${boost_file}.tar.gz \
    && rm ${boost_file}.tar.gz \
    && cd ${boost_file} \
    && ./bootstrap.sh \
    && ./b2 --without-python --prefix=/usr -j 4 link=shared runtime-link=shared install \
    && cd .. \
    && rm -rf ${boost_file} \
    && ldconfig

ARG USER=zal
RUN adduser $USER && echo zal | passwd --stdin $USER
RUN echo "$USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
RUN sed -ri 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
RUN ssh-keygen -t rsa -N "" -f /etc/ssh/ssh_host_rsa_key

RUN rpm -ivh https://dev.mysql.com/get/Downloads/Connector-C++/mysql-connector-c++-1.1.12-linux-el7-x86-64bit.rpm

EXPOSE 22

CMD ["/usr/sbin/sshd", "-D"]
