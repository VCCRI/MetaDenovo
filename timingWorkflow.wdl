workflow timingWorkflow {
    scatter(i in range(15)) {
        call sleep { input: sleep_time = i }
    }
}

task sleep {
    Int sleep_time
    command {
        echo "I slept for ${sleep_time}"
        sleep ${sleep_time}
    }
	runtime {
        docker: "ubuntu:18.04"
        memory: "1GB"
        cpu: 1
        disks: "local-disk"
    }
    output {
        String out = read_string(stdout())
    }
}