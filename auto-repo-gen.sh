uthor: TJ Edens

PROJECT_DIR=$(pwd);
PROJECT_NAME=$1;
NEW_DIR=$PROJECT_DIR/$PROJECT_NAME;
COMP=$2;
if [[ $COMP = ^[Cc]omposer$ ]]
then
	composer update -o;
	ant;
	read -p "Did ant build the project completely and you recieved a build successful message? " -n 1 -r;
echo " ";
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    echo "Something is wrong with either your environment or the base project has a bug, contact senior backend dev for more help.";
    exit 1;
fi	

read -p "Are you ready to push the first commit to master to start the repo? " -n 1 -r;
echo " ";
if [[  $REPLY =~ ^[Yy]$ ]]
then
    	git push origin master;
	exit 1;
fi

fi

## Make the new project dir and initialize git.

mkdir $NEW_DIR;
cd $NEW_DIR;
git init;

## Add the origin to the new repo that should already be created.

git remote add origin ssh://git@github.com/singlehopllc/$PROJECT_NAME;

## Add the php-symfony-2 base project from git.

read -p "Please reply with either 1, 2, or 3. Is this a Base PHP (1), Symfony2 PHP (2), or Phalcon (3) project? " -n 1 -r;
if [[ $REPLY =~ ^'1'$ ]]
then
        #TYPE='';
	echo "There is no github base project for Base PHP";
	exit 1;
fi

if [[  $REPLY =~ ^'2'$ ]]
then
	TYPE='php-symfony2-base-project';
fi

if [[  $REPLY =~ ^'3'$ ]]
then
        #TYPE='';
	echo "There is no github base project for Phalcon";
	exit 1;
fi
REPLY=

git remote add base https://github.com/singlehopllc/$TYPE;

## Fetch the base project.

git fetch base;

git branch -a

read -p "Is the origin and base displayed? " -n 1 -r;
echo " ";
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    echo "Cancelling script as something went wrong with the origin/base fetch.";
    exit 1;
fi

git branch base-master base/master;
touch .gitignore;
git add .gitignore;

git commit -m "Initial";

git merge --squash --no-commit --allow-unrelated-histories base/master


git commit --amend;

git log

read -p "Is there a change-id? " -n 1 -r;
echo " ";
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    echo "Cancelling script as something went wrong with the git merge/commits.";
    exit 1;
fi

FILES=$(grep -iRl 'BaseProject\|baseproject\|base project' .);

for i in $(echo $FILES); do sed -i -e "s/BaseProject/$PROJECT_NAME/g" $i; done;
for i in $(echo $FILES); do sed -i -e "s/baseproject/$PROJECT_NAME/g" $i; done;
for i in $(echo $FILES); do sed -i -e "s/base project/$PROJECT_NAME/g" $i; done;


echo "Please keep in mind that this can take a few minutes";
composer update -o;

read -p "Did composer complile everything correctly? " -n 1 -r;
echo " ";
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    echo "You most likely need to increase your PHP memory limit to 4096MB, then re-run the script with 'new-sym2 $projec_name composer' to avoid the rest of the stuff this script does.";
    exit 1;
fi

ant;

read -p "Did ant build the project completely and you recieved a build successful message? " -n 1 -r;
echo " ";
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    echo "Something is wrong with either your environment or the base project has a bug, contact senior backend dev for more help.";
    exit 1;
fi

read -p "Are you ready to push the first commit to master to start the repo? " -n 1 -r;
echo " ";
if [[  $REPLY =~ ^[Yy]$ ]]
then
        git push origin master;
        exit 1;
fi
