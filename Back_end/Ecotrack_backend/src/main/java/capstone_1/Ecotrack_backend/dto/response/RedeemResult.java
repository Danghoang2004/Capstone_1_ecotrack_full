package capstone_1.Ecotrack_backend.dto.response;

public class RedeemResult {
    private boolean success;
    private String message;

    public static RedeemResult ok() {
        return new RedeemResult(true, "Đổi voucher thành công");
    }

    public static RedeemResult fail(String message) {
        return new RedeemResult(false, message);
    }

    private RedeemResult(boolean success, String message) {
        this.success = success;
        this.message = message;
    }

    public boolean isSuccess() {
        return success;
    }

    public String getMessage() {
        return message;
    }
}

