#!/bin/sh

PERMSET_NAME=TradeAccess

while [ ! -n "$ORG_NAME"  ] 
do
	echo "🐱  Please enter a name for your scratch org:"
	read ORG_NAME
done

echo "🐱  Building your org, please wait."
sfdx force:org:create -f config/project-scratch-def.json -a ${ORG_NAME} --json

if [ "$?" = "1" ] 
then
	echo "🐱 Can't create your org."
	exit
fi

echo "🐱 Scratch org created."
echo "🐱  Pushing the code, please wait. It may take a while."

sfdx force:source:push -u ${ORG_NAME}

if [ "$?" = "1" ]
then 
	echo "🐱  Can't push your source."
	exit 
fi

echo "🐱  Code is pushed successfully."

sfdx force:user:permset:assign -n ${PERMSET_NAME} -u ${ORG_NAME} --json

if [ "$?" = "1" ]
then
	echo "🐱  Can't assign the permission set."
	exit 
fi	

echo "🐱  Permission set is assigned successfully."

echo "🐱  About to execute tests now."

sfdx force:apex:test:run --classnames TradeControllerTest --synchronous -u ${ORG_NAME} --json

if [ "$?" = "1" ]
then
	echo "🐱  Tests failed."
	exit 
fi	

echo "🐱  Tests ran successfully."

echo "🐱  Creating Chatter Group."

sfdx force:data:record:create -s CollaborationGroup -v "Name='Trade reviewers' CollaborationType='private'" -u ${ORG_NAME} --json

if [ "$?" = "1" ]
then
	echo "🐱  Chatter group creation failed."
	exit 
fi	

echo "🐱  Chatter group created successfully."

sfdx force:org:open -u ${ORG_NAME}