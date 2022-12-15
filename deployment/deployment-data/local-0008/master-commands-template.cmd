write-file master-ready READY

#========================================
# Wrap up                                
#========================================

# Wait for all slaves, even if they were not involved in experiments.
# Wait for slaves.
wait for slaves 1client 1
wait for slaves peers 8

# Stop all slaves.
stop __all__
wait for 3s
