# checkdns
checkdns.sh is a small script that checks for suspicious behaviour in DNS servers by
asking them to resolve well known / possibly targeted domains in attacks and comparing
their answer with a well known good DNS server, like Google. I've used it while working
on a DNS changer malware family described on my blog post called [
DNS Changer Malware Sets Sights on Home Routers] (http://blog.trendmicro.com/trendlabs-security-intelligence/dns-changer-malware-sets-sights-on-home-routers/)
from May, 2015.

The script runs in Linux and OS X, and maybe Windows via Cygwin too.

## Usage

1. First of all it is a good idea to edit checkdns.sh script and put some domains that attackers
may have be interested to hijack in your region, like bank domains, social networks, e-mail providers, etc.
The default configuration has some Brazilian banks, social networks and ads services domains but I strongly encourage
you to customize it. The default configuration is as follows:

```bash
# Domains to check
sites=( itau.com.br bradesco.com.br hsbc.com.br bb.com.br caixa.gov.br \
banrisul.com.br facebook.com.br facebook.com gmail.com hotmail.com \
hotmail.com.br serasaexperian.com.br mercadolivre.com.br pagseguro.com.br \
paypal.com paypal.com.br youtube.com youtube.com.br googleadservices.com \
googlesyndication.com doubleclick.net tam.com.br googletagmanager.com \
googleapis.com )
```
2. After customizing the domain list you have to give execution permission to checkdns.sh script:

```
$ chmod +x checkdns.sh
```

3. In the following example we check two DNS servers, 188.138.102.77 and 188.138.102.78
for malicious behaviour. As checkdns has a built-in list of possible targeted domains
(that you should expand as you wish), we are able to tag an aswer as suspicious:

```
$ ./checkdns.sh 188.138.102.77 188.138.102.78
Mon Jun  1 07:22:58 EDT 2015 [188.138.102.77] oddly resolved itau.com.br to 198.11.253.186
Mon Jun  1 07:22:59 EDT 2015 [188.138.102.77] oddly resolved bradesco.com.br to 198.11.253.186
Mon Jun  1 07:23:00 EDT 2015 [188.138.102.77] oddly resolved hsbc.com.br to 198.11.253.186
Mon Jun  1 07:23:01 EDT 2015 [188.138.102.77] oddly resolved bb.com.br to 198.11.253.186
Mon Jun  1 07:23:02 EDT 2015 [188.138.102.78] oddly resolved itau.com.br to 198.11.253.186
Mon Jun  1 07:23:03 EDT 2015 [188.138.102.78] oddly resolved bradesco.com.br to 198.11.253.186
Mon Jun  1 07:23:04 EDT 2015 [188.138.102.78] oddly resolved hsbc.com.br to 198.11.253.186
Mon Jun  1 07:23:05 EDT 2015 [188.138.102.78] oddly resolved bb.com.br to 198.11.253.186
```
You can also increse verbosity level using -v or -vv parameters.

## Analyzing the results

Keep in mind that checkdns.sh **is NOT** able to say a DNS server is compromised.
It just gives you an indicator something may have happened and would be a good idea
to manually check the server you are testing. Nothing more.
