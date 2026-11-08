package xmagemobile.bridge;

interface Outbox {
    boolean isOpen();

    void send(String message);
}
