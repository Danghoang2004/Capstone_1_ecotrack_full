package capstone_1.Ecotrack_backend.service;

import java.util.concurrent.ConcurrentHashMap;

public class OtpStore {

    private static final ConcurrentHashMap<String, OtpData> STORE = new ConcurrentHashMap<>();

    public static void save(String email, OtpData data) {
        STORE.put(email, data);
    }

    public static OtpData get(String email) {
        return STORE.get(email);
    }

    public static void remove(String email) {
        STORE.remove(email);
    }

}