#!/bin/bash

Print_Sucess_Info()
{
    if [ -s /bin/ss ]; then
        ss -ntl
    else
        netstat -ntl
    fi
    stop_time=$(date +%s)
    echo "Install lops takes $(((stop_time-start_time)/60)) minutes."
    Echo_Green "Install lops V${LOps_Ver} completed! enjoy it."
}

