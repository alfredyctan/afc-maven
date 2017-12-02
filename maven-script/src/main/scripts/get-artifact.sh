#!/bin/sh

usage()	{
	echo "missing $1"
	echo "Usage: $0	-r <repo-url> -g <group-id> -a <artifact-id> [-c classifier] [-t type] [-u <username> -p <password>] [-o output directory] [-q:quiet mode]"
	exit 1
}

while getopts "r:u:p:g:a:c:t:v:o:q" OPT;
do
	case $OPT in
	r)
		REPO_URL=$OPTARG
		;;
	u)
		USERNAME="--http-user ${OPTARG}"
		;;
	p)
		PASSWORD="--http-password ${OPTARG}"
		;;
	g)
		GROUP_ID=${OPTARG}
		;;
	a)
		ARTIFACT_ID=${OPTARG}
		;;
	v)
		VERSION=${OPTARG}
		;;
	c)
		CLASSIFIER="-${OPTARG}"
		;;
	t)
		TYPE=${OPTARG}
		;;
	o)
		OUTPUT=${OPTARG}
		OUTPUT_OPT="-P ${OPTARG}/"
		;;
	q)
		QUIET="-q"
		;;
	*)
		echo "Usage: $0 -r <repo-url> -g <group-id>	-a <release|latest|artifact-id> [-u <username>	-p <password>]"
		exit 1
		;;
	esac
done
shift $((OPTIND-1))

[ -z $REPO_URL ] && usage "repo-url"
[ -z $GROUP_ID ] && usage "group-id"
[ -z $ARTIFACT_ID ] && usage "artifact-id"
[ -z $VERSION ]	&& usage "version"

WGET_OPTS="--no-check-certificate ${QUIET}"

#resolve artifact version
TYPE=${TYPE:-"jar"}
GROUP_ID_PATH=`echo $GROUP_ID |	sed "s/\./\//g"`
METADATA_URL="$REPO_URL/$GROUP_ID_PATH/$ARTIFACT_ID/maven-metadata.xml"
METADATA=`mktemp maven-metadata.xml.XXXXXX`
wget $WGET_OPTS	-O $METADATA $METADATA_URL
case $VERSION in
	release)
		ARTIFACT_VERSION=`grep -e "<release>.*<\/release>" $METADATA | sed "s/^.*<release>//g" | sed "s/<\\/release>.*$//g"`
		;;
	latest)
		ARTIFACT_VERSION=`grep -e "<latest>.*<\/latest>" $METADATA | sed "s/^.*<latest>//g" | sed "s/<\\/latest>.*$//g"`
		;;
	*)
		ARTIFACT_VERSION=$VERSION
		;;
esac
rm $METADATA

#resolve artifact file version
if [[ $ARTIFACT_VERSION	=~ "-SNAPSHOT" ]]; then
	SNAPSHOT_METADATA_URL="$REPO_URL/$GROUP_ID_PATH/$ARTIFACT_ID/$ARTIFACT_VERSION/maven-metadata.xml"
	SNAPSHOT_METADATA=`mktemp maven-metadata.xml.XXXXXX`
	wget $WGET_OPTS	-O $SNAPSHOT_METADATA $SNAPSHOT_METADATA_URL
	FILE_VERSION=`grep -e "<value>.*</value>" $SNAPSHOT_METADATA | tail -n 1 | sed "s/^.*<value>//g" | sed "s/<\\/value>//g"`
else
	FILE_VERSION=$ARTIFACT_VERSION
fi
rm -f $SNAPSHOT_METADATA

ARTIFACT_URL="$REPO_URL/$GROUP_ID_PATH/$ARTIFACT_ID/$ARTIFACT_VERSION/$ARTIFACT_ID-${FILE_VERSION}${CLASSIFIER}.$TYPE"
[ -n $OUTPUT ] && mkdir -p $OUTPUT
wget $WGET_OPTS	$USERNAME $PASSWORD $OUTPUT_OPT $ARTIFACT_URL

if [ ! -f "${OUTPUT}/$ARTIFACT_ID-${FILE_VERSION}${CLASSIFIER}.$TYPE" ]; then
	echo "failed to download $ARTIFACT_URL" 
	usage "type or classifier?"
fi

