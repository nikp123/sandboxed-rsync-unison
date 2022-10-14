Why and how?
------------

Anyway, this is exclusevely set up so you can "securely" have multiuser on a
SSH+rsync/unison server.

All you need is a docker installed and free space on your thing.

So as to how, it merely isolated every user into their own directory and
provides a shell that is restritcted that doesn't allow running anything
apart from said 'unison' and 'rsync' executables.

This version ALSO supports having the ```/users``` directory having the specific
permissions that you need (but at the cost of security as Docker is running in
privileged mode). This allows for easy integration in fxp. Nextcloud or any other
Web-based file management solution.

NO, I meant how do I use this !?
------------------------

oh. Look at the docker-compose.yaml thing.

 * You'll need to have public SSH keys of users you want on there
 (no passwords because bad idea anyway) and bind that to ``/keys``.
 The file convetion is ``/keys/$username.pub`` ie. ``/keys/user.pub``.

 * Within the docker-compose thing you also have an environmental variable
 ``USERS``. There you'll have to set up each user with their own UID as such: 
```
USERS="user1:1000;user2:1001:1002;"
```
where user1's UID is 1000 and user2's UID is 1001, but (optionally) has it's
group set to 1002 (in case you need fancier permission control).

 * You'll need to specify what ``EXTERNAL_USER`` the container is to be bounded to.
You can do either EXTERNAL_USER="$UID" or EXTERNAL_USER="$UID:$GID" if GID needs to
be different from the external user's UID.

 * You will **NEED** to give ``SYS_ADMIN`` permissions and the ``/dev/fuse`` device block.

 * Provide a bind for ``/users`` as it's the designated area where file will be
 stored.

 * Port forward 22 for SSH or any other port that you prefer.

```
docker build -t isolated_rsync .
docker-compose up -d
```

 * (Optionally) bind /etc/ssh for host keys. If you want custom ones, I guess.

You're done. Now just use rsync or Unison.

License
-------

i cant be bothered.

