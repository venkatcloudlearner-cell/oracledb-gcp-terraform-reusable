"""Validate the two new subnet ranges before Terraform planning."""
import ipaddress
import sys


def validate(client, database):
    ranges = [ipaddress.IPv4Network(value, strict=True) for value in (client, database)]
    private = [ipaddress.IPv4Network(value) for value in ("10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16")]
    if any(not any(network.subnet_of(block) for block in private) for network in ranges):
        raise ValueError("Use RFC1918 private IPv4 subnet ranges.")
    if ranges[0].overlaps(ranges[1]):
        raise ValueError("Application and ODB subnet ranges must not overlap.")
    return ranges


if __name__ == "__main__":
    try:
        validate(*sys.argv[1:])
    except (ValueError, TypeError) as exc:
        raise SystemExit(f"Invalid network inputs: {exc}")
    print("New subnet CIDRs are valid and do not overlap each other. Check connected networks separately.")
