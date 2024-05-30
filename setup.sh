# debug
# set -o xtrace

KEY_NAME="cloud-1parking-lot-`date +'%N'`"
KEY_PEM="$KEY_NAME.pem"

echo "create key pair $KEY_PEM to connect to instances and save locally"
aws ec2 create-key-pair --key-name $KEY_NAME \
    | jq -r ".KeyMaterial" > $KEY_PEM

chmod 400 $KEY_PEM

SEC_GRP="my-sg-`date +'%N'`"

echo "setup firewall $SEC_GRP"
aws ec2 create-security-group   \
    --group-name $SEC_GRP       \
    --description "Access my instances" 


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

AMAZON_LINUX_2024="ami-0bb84b8ffd87024d8"

echo "Creating Ubuntu 20.04 instance..."
RUN_INSTANCES=$(aws ec2 run-instances   \
    --image-id $AMAZON_LINUX_2024        \
    --instance-type t2.micro            \
    --key-name $KEY_NAME                \
    --security-groups $SEC_GRP)
    

INSTANCE_ID=$(echo $RUN_INSTANCES | jq -r '.Instances[0].InstanceId')

echo "Waiting for instance creation..."
aws ec2 wait instance-running --instance-ids $INSTANCE_ID

PUBLIC_IP=$(aws ec2 describe-instances  --instance-ids $INSTANCE_ID | 
    jq -r '.Reservations[0].Instances[0].PublicIpAddress'
)

echo "New instance $INSTANCE_ID @ $PUBLIC_IP"

echo "deploying code to production"
scp -i $KEY_PEM -o "StrictHostKeyChecking=no" -o "ConnectionAttempts=60" main.py ec2-user@$PUBLIC_IP:/home/ec2-user

echo "setup production environment"
ssh -i $KEY_PEM -o "StrictHostKeyChecking=no" -o "ConnectionAttempts=10" ec2-user@$PUBLIC_IP <<EOF
    sudo yum update
    sudo yum install python3-flask -y git
    # Check if the repository already exists
    if [ -d "/home/ec2-user/CloudParkingLot" ]; then
        echo "Repository exists. Pulling the latest changes..."
        cd /home/ec2-user/CloudParkingLot
        git pull
    else
        echo "Cloning the repository..."
        git clone https://github.com/sizarnaw/CloudParkingLot.git /home/ec2-user/CloudParkingLot
        cd /home/ec2-user/CloudParkingLot

    nohup flask run --host 0.0.0.0 --port 8000  &>/dev/null &
    exit
EOF

echo
echo "test that it all worked"
echo
echo "This is the IP of the Current instance: $PUBLIC_IP"
echo
echo "Example for insert a car: curl -X POST http://3.84.242.93:8000/entry?plate=123-123-123&parkingLot=382"
echo
curl -X POST "http://$PUBLIC_IP:8000/entry?plate=123-123-123&parkingLot=382"
echo
echo "Example for exit that car curl -X POST http://$PUBLIC_IP:8000/exit?ticketId=7360"
echo
curl -X POST "http://$PUBLIC_IP:8000/exit?ticketId=0"