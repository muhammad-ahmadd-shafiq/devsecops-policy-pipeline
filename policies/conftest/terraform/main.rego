
package main

# Rule 1: EC2 instances must not have public IP addresses.
deny contains msg if {
    some name
    some i

    instance := input.resource.aws_instance[name][i]

    instance.associate_public_ip_address == true

    msg := sprintf(
        "EC2 instance '%s' must not have a public IP address.",
        [name],
    )
}

# Rule 2A: EC2 instances must define a root EBS volume.
deny contains msg if {
    some name
    some i

    instance := input.resource.aws_instance[name][i]
    volumes := object.get(instance, "root_block_device", [])

    count(volumes) == 0

    msg := sprintf(
        "EC2 instance '%s' must define a root EBS volume.",
        [name],
    )
}

# Rule 2B: Every root EBS volume must be encrypted.
deny contains msg if {
    some name
    some i
    some j

    instance := input.resource.aws_instance[name][i]
    volumes := object.get(instance, "root_block_device", [])
    volume := volumes[j]

    volume.encrypted != true

    msg := sprintf(
        "EC2 instance '%s' must encrypt every root EBS volume.",
        [name],
    )
}

# Rule 3: SSH must not be exposed to the entire internet.
deny contains msg if {
    some name
    some i
    some j

    security_group := input.resource.aws_security_group[name][i]
    ingress_rules := object.get(security_group, "ingress", [])
    rule := ingress_rules[j]

    rule.protocol == "tcp"
    rule.from_port <= 22
    rule.to_port >= 22

    cidrs := object.get(rule, "cidr_blocks", [])
    "0.0.0.0/0" in cidrs

    msg := sprintf(
        "Security group '%s' must not expose SSH to 0.0.0.0/0.",
        [name],
    )
}
