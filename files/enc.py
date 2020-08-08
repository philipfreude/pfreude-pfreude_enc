#!/usr/bin/env python3

import yaml


def main():
    result = {
        "classes": [],
        "parameters": [],
    }
    print(yaml.dump(result))


if __name__ == '__main__':
    main()
