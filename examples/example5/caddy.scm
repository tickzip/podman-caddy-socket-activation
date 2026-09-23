(define-module (caddy)
  #:use-module (guix gexp)
  #:use-module (gnu services)
  #:use-module (gnu home services)
  #:use-module (gnu services containers)
  #:use-module (gnu packages containers)
  #:use-module (gnu home services shepherd)
  #:use-module (gnu home services containers))

(define-public caddy-service
  (list
   (service home-oci-service-type
            (for-home
             (oci-configuration
              (runtime 'podman)
              (verbose? #t))))

   (simple-service 'home-oci-provisioning
                   home-oci-service-type
                   (oci-extension
                    (volumes
                     (list
                      (oci-volume-configuration (name "caddy-data"))
                      (oci-volume-configuration (name "caddy-config"))))))

   (simple-service 'caddy
                   home-shepherd-service-type
                   (list
                        (shepherd-service
                         (provision '(caddy))
                         (start #~(make-systemd-constructor
                                   '(#$(file-append podman "/bin/podman")
                                       "run"
                                       "--rm"
                                       "--name" "caddy"
                                       "--security-opt=no-new-privileges"
                                       "--read-only"
                                       "--volume"
                                       #$(string-append (getenv "HOME")
                                                        "/caddy_etc/Caddyfile:/etc/caddy/Caddyfile")
                                       "--volume" "caddy-config:/config"
                                       "--volume" "caddy-data:/data"
                                       "docker.io/library/caddy")
                                   (list
                                    (endpoint (make-socket-address AF_INET6 IN6ADDR_ANY 80)
                                              #:name "caddy-http1")
                                    (endpoint (make-socket-address AF_INET6 IN6ADDR_ANY 443)
                                              #:name "caddy-http2")
                                    (endpoint (make-socket-address AF_INET6 IN6ADDR_ANY 443)
                                              #:name "caddy-http3"
                                              #:style SOCK_DGRAM))))
                         (stop #~(make-systemd-destructor))
                         (documentation "Socket-activated Caddy container."))))))
