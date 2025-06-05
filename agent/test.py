https://grok.com/share/bGVnYWN5_1a4ccaf1-bc56-4a77-98c7-31f09fce21d2



# Pseudo-code for parsing FlexConf
def parse_fcf(file_content):
    config = {}
    templates = {}
    for line in file_content.splitlines():
        line = line.strip()
        if not line or line.startswith('#'):
            continue
        key, value = line.split('=', 1)
        key = key.strip()
        value = value.strip()
        
        # Handle templates
        if key.startswith('template.'):
            template_name = key.split('.', 1)[1]
            templates[template_name] = parse_value(value)
        else:
            config[key] = parse_value(value)
    return config

def parse_value(value):
    if value.startswith('[') and value.endswith(']'):
        return [parse_single_value(v.strip()) for v in value[1:-1].split(',')]
    elif value.startswith('|'):
        return '\n'.join(line.strip() for line in value.splitlines()[1:])
    elif value.startswith('${') and value.endswith('}'):
        return handle_substitution(value[2:-1])
    return parse_single_value(value)

def parse_single_value(value):
    if value in ('true', 'false'):
        return value == 'true'
    if value.isdigit():
        return int(value)
    if value.replace('.', '').isdigit():
        return float(value)
    return value  # string by default

# Example usage
config_str = """
app_name = MyApplication
port = 8080
servers = [web1, web2]
database.host = localhost
description = |
  Line 1
  Line 2
"""
config = parse_fcf(config_str)
print(config)
