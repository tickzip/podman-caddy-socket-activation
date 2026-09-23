return to [main page](../..)

## Example 5

_Example 5_ is similar to [_Example 3_](../example3/README.md) but _Example 5_ uses GNU Shepherd to run podman.

``` mermaid
graph TB

    a1[curl https&colon;//example.com] -.->a2[caddy container]
```

Set up a shepherd user service _caddy_ where rootless podman is
running a _docker.io/library/caddy_ container. Configure _socket activation_ for the ports 80/TCP,
443/TCP and 443/UDP. A TLS certificate is automatically retrieved with the
[ACME](https://en.wikipedia.org/wiki/Automatic_Certificate_Management_Environment) prototol.
Caddy is configured to reply _hello world_.

1. Verify that unprivileged users are allowed to open port numbers 80 and above.
   Run the command
   ```
   cat /proc/sys/net/ipv4/ip_unprivileged_port_start
   ```
   Make sure the number printed is not higher than 80. To configure the number,
   see https://rootlesscontaine.rs/getting-started/common/sysctl/#allowing-listening-on-tcp--udp-ports-below-1024
   or https://guix.gnu.org/manual/1.5.0/en/html_node/Miscellaneous-Services.html#index-sysctl_002dservice_002dtype.
1. Verify that the domain names _example.com_ resolves to
   the IP address of the host's main IPv4 interface.
   Run commands to resolve the hostnames.
   ```
   host example.com
   ```
   Verify that the result matches the left-most IPv4 address shown by the command `hostname -I`.
1. Pull _caddy_ container image
   ```
   podman pull docker.io/library/caddy
   ```
1. Clone git repo
   ```
   git clone https://github.com/eriksjolund/podman-caddy-socket-activation.git
   ```
1. Install the service's module
   ```
   cp podman-caddy-socket-activation/examples/example5/caddy.scm \
      ~/.config/
   ```
1. Install the _Caddyfile_
   ```
   cp podman-caddy-socket-activation/examples/example5/Caddyfile \
      ~/caddy_etc/Caddyfile
   ```
   (The path _~/caddy_etc/Caddyfile_ was arbitrarily chosen)
1. Edit _~/caddy\_etc/Caddyfile_ so that _example.com_ is replaced with the hostname of
   your computer.
1. Edit your existing Guix Home configuration to add the _caddy_ service.
   ```
   (use-modules (caddy))

   (home-environment
        ;; ...
        (services (append (list caddy-service)
                          %base-home-services)))
   ```
1. Apply the configuration to your home environment. Listening sockets on ports
   80/TCP, 443/TCP, 443/UDP will then be created.
   ```
   guix home reconfigure -L ~/.config </path/to/home-config>
   ```
1. View the status of the caddy service.
   ```
   herd status caddy
   ```
1. Run curl to download the hello world example
   ```
   curl -s https://example.com
   ```
   The following output is printed
   ```
   Hello world
   ```

### Discussion

Note that the shepherd service is set to create IPv6-only sockets. To listen on
IPv4, change the socket-address from `AF_INET6 IN6ADDR_ANY` to `AF_INET
INADDR_ANY`.

In the example caddy fetches a TLS certificate with the ACME protocol.

An alternative to this is to provide the TLS certificate yourself by specifying
a path to a cert file and a path to a key file. For details, see
https://caddyserver.com/docs/caddyfile/directives/tls

If you provide the TLS certificate yourself, then the caddy container does not
need to create any outgoing TCP connections for the ACME protocol.
You could then add the configuration line

```
"--network=none"
```

to the podman arguments in file _caddy.scm_. This improves security.
For details, see the blog post
[_How to limit container privilege with socket activation_](https://www.redhat.com/sysadmin/socket-activation-podman)
