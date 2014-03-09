# VM Reverter

This gem is used to revert a collection of virtual machines from many hypervisor frameworks using a yaml file back to specific snapshots.

## Supported Hypervisors

* VMWare VSphere Server [vshpere] ~> rbvmomi
* AWS [aws] ~> Blimpy / Fog

## Vsphere Credentials

```yaml
# ~/.fog
:default:
  :vsphere_server: 'vsphere.mydomain.com'
  :vsphere_username: 'john_doe'
  :vsphere_password: '$3cr3+_$@uc3'
```
## Configuration File

### Required YAML Header:

* HOSTS
* vm-name 

### Required Fields:

* snapshots
* hypervisor

### Optional fields:

* power - overide the saved state of the power of the snapshot [up|down|destroy]
* tag - add a meta tag to a host

## Configuration File - Revert

revert.conf

```yaml
HOSTS:
  test-server01:
    hypervisor: vsphere
    snapshot: gold-image
    tag: interesting
    power: up
  test-server02:
    hypervisor: vsphere
    snapshot: gold-image
  test-server03:
    hypervisor: aws
      aws-options:
        ami-size: m1.small
        ami-region: us-west-2
        security-group: clients
```


### Configuration Example - Stop VMS

This configuration will remove the hosts from aws.

```yaml
HOSTS:
  test-server01:
    hypervisor: aws
    power: down
  test-server02:
    hypervisor: vsphere
    power: down
```


### Configuration Example - Destruction

This configuration will remove the hosts from the hypervisor (aws only).

```yaml
HOSTS:
  test-server01:
    hypervisor: aws
    power: destroy
  test-server02:
    hypervisor: aws
    power: destroy
```

## CLI Usage

Using local conf file and turning on all machines after reverting.

```
$> vmreverter -c ./revert.conf 
```
## Tested Against

* Ruby 1.9.3
* VSphere 5.5

## TODO

* Unit Tests
* API Mocks

Further Hypervisor implementations:

* OpenStack ~> Blimpy
* VirtualBox ~> Vagrant


## Legal notes

This is some wildly refactored code (..legal speak..) from the puppet_acceptance gem. puppet labs, puppet_acceptance, or its authors do not endorse this code.

Changes include namespace swaps, class additions, class removals, method additions, method removals, and complete code refactoring.

All original code maintains its copyright from its original author(puppetlabs) and licensing of Apache 2, and only change sets from git rev 

https://github.com/puppetlabs/puppet-acceptance/commit/68272162d0b30905f498a4d71ff641374d3eb8f0

onward (circa Feb 2014) within the vmreverter namespace will include permissive of BSD-3 LICENSING as such approved by law. 
