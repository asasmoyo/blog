---
title: "Konfigurasi Replikasi di PostgreSQL 11"
date: 2018-10-21T13:45:33+07:00
draft: false
---

Yay PostgreSQL 11 baru saja keluar bulan lalu (lihat [di sini](https://news.ycombinator.com/item?id=18248050) untuk diskusi HN). Yuk kita coba mengkonfigurasi replikasi di PostgreSQL 11.

# Replikasi di PostgreSQL

Replikasi di PostgreSQL didasarkan pada teknologi Write Ahead Log (WAL). Fungsi WAL sangat simpel. Seperti namanya, WAL menjadikan PostgreSQL untuk menulis log sebelum setiap perubahan yang terjadi. Perubahan data tidak akan dilakukan sebelum WAL berhasil disimpan ke storage. Log ini berisi perubahan yang dilakukan kepada PostgreSQL. Dengan demikian integritas data di PostgreSQL dapat terjamin. Apabila server crash sebelum perubahan data dilakukan, PostgreSQL dapat membaca WAL terakhir dan menjalankannya lagi. Selain itu, apabila kita memiliki WAL yang lengkap, kita dapat menjalankan ulang seluruh WAL dari awal sampai akhir untuk mendapatkan state terakhir. Sehingga WAL juga dapat digunakan untuk mekanisme backup juga.

Fungsi WAL tidak hanya itu saja. Bagaimana jika kita mengirim WAL dari server PostgreSQL A ke server B, dan server B langsung menjalankan WAL ketika menerimanya. Yap, server B akan memiliki state yang sama dengan server A! Inilah yang disebut sebagai _streaming replication_ pada PostgreSQL.

Memang tidak ketika perubahan terjadi di server A, server B seketika itu juga memiliki state yang sama dengan server A. Terdapat delay selama beberapa saat sebelum state server B sama dengan server A. Hal ini dikarenakan diperlukan waktu untuk mengirimkan WAL dari server A ke server B, dan server B juga memerlukan waktu untuk menjalankan WAL yang diterima. Akan tetapi kita bisa menjamin bahwa suatu saat nanti, server B akan memiliki state yang sama dengan server A. Hal ini disebut sebagai _eventually consistent_.

Akan tetapi bagaimana jika terdapat WAL yang hilang di network, sehingga server B tidak akan pernah menerimanya. Jika ini terjadi maka server B tidak akan pernah bisa memiliki state yang sama dengan server A. Untuk mengatasi hal ini, PostgreSQL memiliki fitur untuk menjalankan WAL dari sumber lain. Akan tetapi WAL yang ditulis di server A harus disimpan pada storage yang dapat diakses dari server B.

# Konfigurasi replikasi

Kita akan menggunakan PostgreSQL versi 11 pada server Ubuntu 18.04. Replikasi yang kita buat akan memiliki skema seperti ini:

![diagram](/images/2018-10/postgres-replication-diagram.png)

Kita akan membutuhkan 4 server. Diasumsikan bahwa untuk server berikut dapat melakukan passwordless SSH ke server lain (cek [di sini](https://www.digitalocean.com/community/tutorials/how-to-configure-ssh-key-based-authentication-on-a-linux-server#copying-your-public-key-manually) untuk bagaimana mengkonfigurasi passwordless SSH):

``` bash
primary, slave1, slave2 -> wal_storage
```

`primary` merupakan server utama yang menjalankan perubahan data dari client. Sedangkan `slave1` dan `slave2` merupakan server yang menerima WAL dari `primary`. Sedangkan `wal_storage` merupaan server yang menyimpan WAL yang ditulis dari server `primary`, `slave1` dan `slave2`.

1. Install PostgreSQL 11

    Ikuti langkan [di sini](https://www.postgresql.org/download/linux/ubuntu/) untuk menginstall PostgreSQL 11 di server `primary`, `slave1` dan `slave2`.

1. Membuat user replikasi

    Server slave harus terhubung ke server `primary` untuk mendapatkan akses ke WAL server `primary`. Kita akan menggunakan user khusus untuk ini. Untuk membuatnya, pada server `primary`, `slave1` dan `slave2` masuk ke user `postgres` lalu jalankan perintah berikut:

    ``` bash
    psql -c "create user replicator with replication login;"
    ```

    Opsi `replication` menandakan bahwa user yang dibuat merupakan user khusus yang digunakan untuk replikasi dan opsi `login` memungkinkan user ini untuk melakukan login dari server lain.

1. Konfigurasi `pg_hba.conf`

    PostgreSQL memiliki file `pg_hba.conf` yang befungsi untuk mengatur koneksi yang diijinkan masuk. Agar replikasi dapat berjalan, maka `slave1` dan `slave2` harus dapat mengakses `primary` dengan menggunakan user `replicator`. Untuk itu tambahkan baris berikut pada `/etc/postgresql/11/main/pg_hba.conf`

    ``` bash
    # ganti NETWORK dengan CIDR yang mencakup server primary, slave1 dan slave2
    # misal 10.11.12.0/24
    host replication replicator NETWORK trust
    ```

    Baris tersebut artinya _koneksi yang masuk lewat TCP/IP, yang berasal dari IP yang termasuk CIDR yang didefinisikasn di `NETWORK`, yang menggunakan user `replicator` untuk keperluan `replication`, akan diijinkan_.

    Lakukan ini di server `primary`, `slave1` dan `slave2`.

1. Konfigurasi PostgreSQL

    Buka file `/etc/postgresql/11/main/postgresql.conf` dan sesuaikan/tambahkan konfigurasi untuk:

    ``` bash
    listen_addresses = '*'
    wal_level = 'replica' # diperlukan agar data yang ditulis di WAL dapat digunakan untuk keperluan replikasi
    max_wal_senders = 3 # jumlah proses pengiriman WAL yang diijinkan, paling tidak harus sama dengan jumlah server slave
    wal_keep_segments = 500 # jumlah file WAL yang disimpan
    ```

    Lakukan ini di server `primary`, `slave1` dan `slave2`. Lalu restart service postgres agar PostgreSQL membaca perubahan konfigurasi.

1. Konfigurasi penyimpanan WAL

    Tambahkan baris berikut di `/etc/postgresql/11/main/postgresql.conf`

    ``` bash
    archive_mode = 'on'
    archive_command = 'rsync -az %p $USER@$IP_WAL_STORAGE:~/wals/'
    ```

    Kita menggunakan `archive_command` untuk menyimpan file WAL yang dibuat oleh PostgreSQL di server `wal_storage`. `archive_command` akan dijalankan untuk setiap file WAL yang dibuat oleh PostgreSQL. Kita menggunakan `rsync` untuk menyimpan file WAL. Kenapa `rsync`? Karena kita memiliki 3 server PostgreSQL yang menghasilkan WAL yang sama maka kita harus mengecek apakah file WAL telah disimpan ke storage. Dengan menggunakan `rsync`, kita bisa menghilangkan proses pengecekan tersebut. Karena `rsync` tidak akan melakukan apa apa apabila file WAL telah disimpan.

    Lakukan ini di server `primary`, `slave1` dan `slave2`. Lalu restart service postgres agar PostgreSQL membaca perubahan konfigurasi.

1. Copy state `primary` ke slave

    Jalankan perintah berikut di server `slave1` dan `slave2`

    ``` bash
    systemctl stop postgresql
    rm -rf /var/lib/postgresql/11/main
    pg_basebackup --pgdata=/var/lib/postgresql/11/main --write-recovery-conf --progress --verbose --host=$IP_PRIMARY --username=replicator
    chown -R postgres:postgres /var/lib/postgresql/11/main
    ```

    Perintah di atas akan membuat ulang data PostgreSQL agar memiliki state yang sama dengan `primary`. Selain itu juga mengkonfigurasi _streaming replication_ pada file `/var/lib/postgresql/11/main/recovery.conf` yang berisi:

    ``` bash
    standby_mode = 'on'
    primary_conninfo = 'user=replicator passfile=''/root/.pgpass'' host=IP_PRIMARY port=5432 sslmode=prefer sslcompression=0 krbsrvname=postgres target_session_attrs=any'
    ```

    Tambahkan baris berikut pada `/var/lib/postgresql/11/main/recovery.conf`:

    ``` bash
    restore_command = 'rsync -az $USER@$IP_WAL_STORAGE:~/wals/%f %p'
    ```

    Dengan konfigurasi `recovery.conf` seperti di atas, server akan terus menjalankan WAL yang didapat dari server `primary`. Selain itu, apabila file WAL tidak didapatkan dari _streaming replication_, server akan menjalankan perintah yang terdapat pada `restore_command` untuk mendapatkan file WAL tersebut.

    Selanjutnya jalankan service postgres pada server `slave1` dan `slave2`. Jika konfigurasi benar, akan muncul proses `postgres: 11/main: walsender` pada server `primary` untuk setiap slave yang terhubung.

    ``` bash
    17659 ?        Ss     0:00 postgres: 11/main: walsender replicator IP_SLAVE_1(51648) streaming 0/7000060
    17660 ?        Ss     0:00 postgres: 11/main: walsender replicator IP_SLAVE_2(60446) streaming 0/7000060
    ```

# Tes replikasi

Semua perubahan yang terjadi pada server `primary` akan diikuti oleh server slave juga. Untuk mencobanya dapat dilakukan dengan membuat database / tabel pada server `primary`. Setelah beberapa saat, database / tabel tersebut juga akan muncul pada server slave.

Selain itu, status replikasi dapat juga dilakukan dengan melakukan query berikut di server `primary`

``` bash
postgres=# select * from pg_stat_replication;
-[ RECORD 1 ]----+------------------------------
pid              | 17659
usesysid         | 16384
usename          | replicator
application_name | walreceiver
client_addr      | IP_SLAVE_1
client_hostname  |
client_port      | 51648
backend_start    | 2018-11-15 16:48:02.177309+00
backend_xmin     |
state            | streaming
sent_lsn         | 0/7000140
write_lsn        | 0/7000140
flush_lsn        | 0/7000140
replay_lsn       | 0/7000140
write_lag        |
flush_lag        |
replay_lag       |
sync_priority    | 0
sync_state       | async
-[ RECORD 2 ]----+------------------------------
pid              | 17660
usesysid         | 16384
usename          | replicator
application_name | walreceiver
client_addr      | IP_SLAVE_2
client_hostname  |
client_port      | 60446
backend_start    | 2018-11-15 16:48:05.640884+00
backend_xmin     |
state            | streaming
sent_lsn         | 0/7000140
write_lsn        | 0/7000140
flush_lsn        | 0/7000140
replay_lsn       | 0/7000140
write_lag        |
flush_lag        |
replay_lag       |
sync_priority    | 0
sync_state       | async
```

* * *

Demikianlah fitur replikasi bawaan PostgreSQL. Apabila diperhatikan, replikasi hanya berjalan satu arah. Perubahan dari server `primary` akan direplikasi ke server slave, akan tetapi tidak sebaliknya. Oleh karena itu semua query yang melakukan perubahan ke database harus diarahkan ke server `primary` dan kapasitas perubahan database dibatasi oleh spesifikasi server `primary`. Akan tetapi, query yang membaca data dari database dapat ditujukan ke salah satu server slave. Apabila kebutuhan kapasitas perubahan database sangat besar dan sebuah server `primary` tidak dapat mengatasinya, maka skenario ini tidak dapat digunakan. Terdapat beberapa project lain yang memungkinkan menggunakan skenario multi-master pada PostgreSQL, misalnya [Cockroachdb](https://www.cockroachlabs.com) dan [Citus](https://www.citusdata.com/).
