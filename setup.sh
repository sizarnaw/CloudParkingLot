#!/bin/bash

# debug
# set -o xtrace

KEY_NAME="cloud-course-`date +'%N'`"
KEY_PEM="$KEY_NAME.pem"

echo "create key pair $KEY_PEM to connect to instances and save locally"
aws ec2 create-key-pair --key-name $KEY_NAME \
    | jq -r ".KeyMaterial" > $KEY_PEM

# secure the key pair
chmod 400 $KEY_PEM

SEC_GRP="my-sg-`date +'%N'`"

echo "setup firewall $SEC_GRP"
aws ec2 create-security-group   \
    --group-name $SEC_GRP       \
    --description "Access my instances"

# figure out my ip
MY_IP=$(curl ipinfo.io/ip)
echo "My IP: $MY_IP"

echo "setup rule allowing SSH access to $MY_IP only"
aws ec2 authorize-security-group-ingress        \
    --group-name $SEC_GRP --port 22 --protocol tcp \
    --cidr $MY_IP/32

echo "setup rule allowing HTTP (port 8000) access to all IP"
aws ec2 authorize-security-group-ingress        \
    --group-name $SEC_GRP --port 8000 --protocol tcp \
    --cidr 0.0.0.0/0

UBUNTU_20_04_AMI="ami-03238ca76a3266a07"



echo "Creating Ubuntu 20.04 instance..."
RUN_INSTANCES=$(aws ec2 run-instances   \
    --image-id $UBUNTU_20_04_AMI        \
    --instance-type t3.micro            \
    --key-name $KEY_NAME                \
    --security-groups $SEC_GRP          \
    --user-data $USER_DATA)

INSTANCE_ID=$(echo $RUN_INSTANCES | jq -r '.Instances[0].InstanceId')

echo "Waiting for instance creation..."
aws ec2 wait instance-running --instance-ids $INSTANCE_ID

PUBLIC_IP=$(aws ec2 describe-instances  --instance-ids $INSTANCE_ID | 
    jq -r '.Reservations[0].Instances[0].PublicIpAddress'
)

USER_DATA=$(base64 <<EOF
#!/bin/bash
sudo yum install -y python3-pip git
pip3 install flask
git clone https://github.com/sizarnaw/CloudParkingLot.git /tmp/ParkingLotSystem
cd /tmp/ParkingLotSystem
python3 main.py --host 0.0.0.0  &>/dev/null 
EOF
)

echo "New instance $INSTANCE_ID @ $PUBLIC_IP"

echo
echo "test that it all worked"
echo
echo "This is the IP of the Current instance: $PUBLIC_IP"
echo
echo "Example for insert a car: curl -X POST http://$PUBLIC_IP:8000/entry?plate=123-123-123&parkingLot=382"
echo
curl -X POST "http://$PUBLIC_IP:8000/entry?plate=123-123-123&parkingLot=382"
echo
echo "Example for exit that car curl -X POST http://$PUBLIC_IP:8000/exit?ticketId=0"
echo
curl -X POST "http://$PUBLIC_IP:8000/exit?ticketId=0"
