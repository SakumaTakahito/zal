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
    rsync \
    bzip2-devel \
    zlib-devel \
    make \
    openssl-devel \
    libev-devel

ARG boost_version=1.64.0
ARG boost_file=boost_1_64_0
RUN cd /tmp \
    && scl enable devtoolset-7 bash \
    && wget https://dl.bintray.com/boostorg/release/${boost_version}/source/${boost_file}.tar.gz --no-check-certificate \
    && tar xfz ${boost_file}.tar.gz \
    && rm -f ${boost_file}.tar.gz \
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
RUN sed -ri 's/#UseDNS yes/UseDNS no/g' /etc/ssh/sshd_config
RUN ssh-keygen -t rsa -N "" -f /etc/ssh/ssh_host_rsa_key

#Install MariaDB client depending boost
RUN rpm -ivh https://dev.mysql.com/get/Downloads/Connector-C++/mysql-connector-c++-1.1.12-linux-el7-x86-64bit.rpm

#Install AMQP client
ARG amqp_version=4.1.4
RUN cd /tmp \
    && wget https://github.com/CopernicaMarketingSoftware/AMQP-CPP/archive/v${amqp_version}.tar.gz \
    && tar -zxvf v${amqp_version}.tar.gz \
    && rm -f v${amqp_version}.tar.gz \
    && cd AMQP-CPP-${amqp_version}/ \
    && make \
    && sudo make install \
    && ldconfig

#Install google-test 
ARG cmake_version=3.14.1
ARG googletest_version=1.8.0
RUN cd /tmp \
    && wget https://cmake.org/files/v3.14/cmake-${cmake_version}.tar.gz \
    && tar xvf cmake-${cmake_version}.tar.gz \
    && rm -f cmake-${cmake_version}.tar.gz \
    && cd cmake-${cmake_version} \
    && ./bootstrap \
    && make \
    && sudo make install \
    && cd /tmp \
    && wget https://github.com/google/googletest/archive/release-${googletest_version}.tar.gz \
    && tar xzf release-${googletest_version}.tar.gz \
    && rm -f release-${googletest_version}.tar.gz \
    && cd googletest-release-${googletest_version} \
    && cmake -DBUILD_SHARED_LIBS=ON . \
    && make \
    && sudo make install \
    && mkdir /usr/local/gtest \
    && cd /tmp \
    && mv /tmp/googletest-release-${googletest_version} /usr/local/gtest \
    && ldconfig

#install spdlog, serialize, json, 
ARG spdlog_version=1.3.1
ARG cereal_version=1.2.2
ARG json11_version=1.0.0
RUN cd /tmp \
    && wget https://github.com/gabime/spdlog/archive/v${spdlog_version}.tar.gz \
    && tar xzf v${spdlog_version}.tar.gz \
    && rm -f v${spdlog_version}.tar.gz \
    && mv spdlog-${spdlog_version}/include/spdlog/ /usr/local/include/ \
    && cd /tmp \
    && wget https://github.com/USCiLab/cereal/archive/v${cereal_version}.tar.gz \
    && tar xzf v${cereal_version}.tar.gz \
    && rm -f v${cereal_version}.tar.gz \
    && mv cereal-${cereal_version}/include/cereal/ /usr/local/include/ \
    && cd /tmp  \
    && wget https://github.com/dropbox/json11/archive/v${json11_version}.tar.gz \
    && tar xzf v${json11_version}.tar.gz \
    && rm -f v${json11_version}.tar.gz \
    && cd json11-${json11_version} \
    && cmake -DBUILD_SHARED_LIBS=ON . \
    && make \
    && sudo make install \
    && ldconfig

#install cpp_redis (and tacopie)
RUN cd /tmp \
	&& yum install -y git \
	&& git clone --recursive --depth=1 -b 4.3.1 https://github.com/cpp-redis/cpp_redis.git \
	&& cd cpp_redis \
	&& cmake -DBUILD_SHARED_LIBS=ON . \
	&& make \
	&& sudo make install \
	&& cd tacopie \
	&& cmake -DBUILD_SHARED_LIBS=ON . \
	&& make \
	&& sudo make install \
	&& ldconfig
	
RUN mkdir -p /work && chmod -R 755 /work
