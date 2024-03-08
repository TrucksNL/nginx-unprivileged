# trucksnl/nginx-unprivileged container image
Nginx unprivileged container image with opiniated defaults for PHP-FPM via a Unix socket

## ==> This is still a WORK-IN-PROGRESS ! <==

# Docker example

PHP-FPM configuration file located in `%project_root%/docker/php/www.conf`.
```
[www]
listen = /sock/docker.sock
listen.owner = nobody
listen.group = nobody
listen.mode = 0660
```
(But beware the Docker image of PHP-FPM has a default file located at `/usr/local/etc/php-fpm.d/zz-docker.conf` which overwrites with config `listen = 9000`. Either replace or remove the `zz-docker.conf` file.)
```yaml
version: '3.4'
services:
  nginx:
    image: ghcr.io/trucksnl/nginx-unprivileged:latest
    volumes:
      - 'drawer:/sock'
      - './public/:/var/www/html/public/'
      - '/tmp'
  php:
    image: php:8.3-fpm-alpine
    volumes:
      - 'drawer:/sock'
      - './:/var/www/html/'
      - './docker/php/www.conf:/usr/local/etc/php-fpm.d/www.conf'
volumes:
  drawer:
```

# Kubernetes example

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-php-application
  labels:
    app.kubernetes.io/name: my-php-application
spec:
  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: my-php-application
  template:
    metadata:
      name: my-php-application
      labels:
        app.kubernetes.io/name: my-php-application
    spec:
      containers:
        - name: nginx
          image: ghcr.io/trucksnl/nginx-unprivileged:latest
          imagePullPolicy: IfNotPresent
          ports:
            - containerPort: 8080
              name: http
          resources:
            limits:
              cpu: 100m
              memory: 128Mi
            requests:
              cpu: 10m
              memory: 32Mi
          securityContext:
            privileged: false
            seccompProfile:
              type: RuntimeDefault
            readOnlyRootFilesystem: true
            runAsNonRoot: true
            runAsGroup: 65534
            runAsUser: 65534
          volumeMounts:
            - mountPath: /var/www/html/
              name: shared-public
            - mountPath: /sock
              name: shared-socket
            - mountPath: /tmp
              name: nginx-tmp
        - name: php-fpm
          image: php:8.3-fpm-alpine
          imagePullPolicy: IfNotPresent
          lifecycle:
            postStart:
              exec:
                command:
                  # Copy the public dir so Nginx can host static assets without asking PHP-FPM
                  - sh -c "cp -r /var/www/html/public/ /nginx-public/"
          resources:
            limits:
              cpu: 250m
              memory: 512Mi
            requests:
              cpu: 50m
              memory: 128Mi
          volumeMounts:
            - mountPath: /nginx-public/
              name: shared-public
            - mountPath: /sock
              name: shared-socket
      restartPolicy: Always
      volumes:
        - name: shared-public
          emptyDir: {}
        - name: shared-socket
          emptyDir: {}
        - name: nginx-tmp
          emptyDir: {}
```
