{
	"agent": {
		"metrics_collection_interval": 30,
		"run_as_user": "root"
	},
	"logs": {
		"logs_collected": {
			"files": {
				"collect_list": [
					{
						"file_path": "/var/log/nginx/access.log",
						"log_group_name": "jhoh-accesslog",
						"log_stream_name": "{instance_id}"
					}
				]
			}
		}
	},
	"metrics": {
        "namespace": "jhohnamespace",
		"metrics_collected": {
			"collectd": {
				"metrics_aggregation_interval": 60
			},
			"mem": {
				"measurement": [
					"mem_used_percent"
				],
				"metrics_collection_interval": 30
			}
		}
	}
}