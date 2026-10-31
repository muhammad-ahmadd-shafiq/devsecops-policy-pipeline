
package main

# Test 1: Public EC2 IP must be denied.
test_public_ip_is_denied if {
    count(deny) == 1 with input as {
        "resource": {
            "aws_instance": {
                "test_server": [{
                    "associate_public_ip_address": true,
                    "root_block_device": [{"encrypted": true}]
                }]
            }
        }
    }
}

# Test 2: Unencrypted EBS must be denied.
test_unencrypted_ebs_is_denied if {
    count(deny) == 1 with input as {
        "resource": {
            "aws_instance": {
                "test_server": [{
                    "associate_public_ip_address": false,
                    "root_block_device": [{"encrypted": false}]
                }]
            }
        }
    }
}

# Test 3: Public SSH access must be denied.
test_public_ssh_is_denied if {
    count(deny) == 1 with input as {
        "resource": {
            "aws_security_group": {
                "test_sg": [{
                    "ingress": [{
                        "from_port": 22,
                        "to_port": 22,
                        "protocol": "tcp",
                        "cidr_blocks": ["0.0.0.0/0"]
                    }]
                }]
            }
        }
    }
}

# Test 4: A secure configuration must produce no violations.
test_secure_configuration_is_allowed if {
    count(deny) == 0 with input as {
        "resource": {
            "aws_instance": {
                "test_server": [{
                    "associate_public_ip_address": false,
                    "root_block_device": [{"encrypted": true}]
                }]
            },
            "aws_security_group": {
                "test_sg": [{
                    "ingress": [{
                        "from_port": 22,
                        "to_port": 22,
                        "protocol": "tcp",
                        "cidr_blocks": ["203.0.113.10/32"]
                    }]
                }]
            }
        }
    }
}
