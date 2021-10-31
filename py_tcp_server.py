import socket
s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
port = 1337
# msg=input("What do u wanna say?")
s.bind (('127.0.0.1',port))
s.listen(5)
while True:
    c,addr=s.accept()
    print ('connected with ',addr)
    # c.send (msg.encode())
    while True:
        print(c.recv(1024).decode())
    # c.close()
s.close()