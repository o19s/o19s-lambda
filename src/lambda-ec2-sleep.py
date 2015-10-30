import boto3
ec2 = boto3.resource('ec2')

from datetime import datetime


def sleep_running_instances():
    '''Scans for running instances and stops them.
    '''
    instances = ec2.instances.filter(
        Filters=[{'Name': 'instance-state-name', 'Values': ['running']}])
    ids = [instance.id for instance in instances]
    if len(ids):
        ec2.instances.filter(InstanceIds=ids).stop()
        print('Stopped {}').format(str(ids))
    else:
        print('No instances running.')


def lambda_handler(event, context):
    print('Scanning for running instances.')
    try:
        sleep_running_instances()
    except:
        print('Sleep routiene failed!')
        raise
    else:
        print('Finished sleeping instances!')
        return event['time']
    finally:
        print('Complete at {}'.format(str(datetime.now())))
