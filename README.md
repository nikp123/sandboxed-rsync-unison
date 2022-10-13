Why and how?
------------

Anyway, this is exclusevely set up so you can "securely" have multiuser on a
SSH+rsync/unison server.

All you need is a docker installed and free space on your thing.

So as to how, it merely isolated every user into their own directory and
provides a shell that is restritcted that doesn't allow running anything
apart from said 'unison' and 'rsync' executables.

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

