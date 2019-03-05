# zal

VSでデバッグできるように  
`docker run -d --name zal -p 2222:22 --cap-add=SYS_PTRACE --security-opt="seccomp=unconfined" zal`
