write-file master-ready READY

#========================================
# 0000 (local)
#========================================


# Wait for slaves.
wait for slaves peers 4
wait for slaves 1client 1

# Create log directory.
exec-start __all__ /dev/null mkdir -p experiment-output/0000/slave-__id__/config
exec-wait __all__ 2000

# Prepare config file.
exec-start peers /dev/null cp config/config-0000.yml experiment-output/0000/slave-__id__/config/config.yml
exec-wait peers 2000
exec-start 1client /dev/null cp config/config-0000.yml experiment-output/0000/slave-__id__/config/config.yml
exec-wait 1client 2000
sync peers
sync 1client

# Start peers.
discover-reset 4
exec-start peers experiment-output/0000/slave-__id__/peer.log orderingpeer experiment-output/0000/slave-__id__/config/config.yml 127.0.0.1:9999 127.0.0.1 127.0.0.1 experiment-output/0000/slave-__id__/peer.trc experiment-output/0000/slave-__id__/prof
discover-wait

wait for 2s
# Run clients locally and wait for them to stop.
exec-start 1client experiment-output/0000/slave-__id__/clients.log orderingclient experiment-output/0000/slave-__id__/config/config.yml 127.0.0.1:9999 experiment-output/0000/slave-__id__/client experiment-output/0000/slave-__id__/prof-client
exec-wait 1client 480000 exec-start 1client experiment-output/0000/slave-__id__/FAILED echo Client failed or timed out; exec-wait 1client 2000
sync 1client

# Stop peers.
exec-signal peers SIGINT
wait for 5s

# Update master status.
write-file master-status 0000


#========================================
# Wrap up                                
#========================================

# Wait for all slaves, even if they were not involved in experiments.
# Wait for slaves.
wait for slaves 1client 1
wait for slaves peers 4

# Stop all slaves.
stop __all__
wait for 3s
