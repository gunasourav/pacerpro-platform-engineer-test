import boto3
import json
import logging
import os

logger = logging.getLogger()
logger.setLevel(logging.INFO)

ec2 = boto3.client('ec2')
sns = boto3.client('sns')

def lambda_handler(event, context):
    logger.info('Received: %s', json.dumps(event))
    try:
        INSTANCE_ID = os.environ.get('EC2_INSTANCE_ID')
        SNS_ARN = os.environ.get('SNS_TOPIC_ARN')
        if not INSTANCE_ID or not SNS_ARN:
            raise ValueError('Missing env vars')
        logger.info('Rebooting %s', INSTANCE_ID)
        ec2.reboot_instances(InstanceIds=[INSTANCE_ID])
        msg = f'Instance {INSTANCE_ID} rebooted.'
        logger.info(msg)
        sns.publish(
            TopicArn=SNS_ARN,
            Subject='EC2 Rebooted',
            Message=msg
        )
        logger.info('SNS sent')
        return {'statusCode': 200, 'body': msg}
    except Exception as e:
        logger.error('Error: %s', str(e))
        raise
