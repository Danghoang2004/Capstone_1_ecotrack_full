package capstone_1.Ecotrack_backend.service;

// src/main/java/com/ecotrack/admin/service/DashboardService.java

import capstone_1.Ecotrack_backend.dto.response.DashboardCampaignParticipationDto;
import capstone_1.Ecotrack_backend.dto.response.DashboardLevelDistributionDto;
import capstone_1.Ecotrack_backend.dto.response.DashboardResponse;
import capstone_1.Ecotrack_backend.dto.response.DashboardRecentActivityDto;
import capstone_1.Ecotrack_backend.dto.response.MonthlyActivityDto;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

import java.sql.Timestamp;
import java.time.YearMonth;
import java.time.YearMonth;
import java.util.*;

@Service
public class DashboardService {

        private final JdbcTemplate jdbcTemplate;

        public DashboardService(JdbcTemplate jdbcTemplate) {
                this.jdbcTemplate = jdbcTemplate;
        }

        public DashboardResponse getDashboard() {
                DashboardResponse res = new DashboardResponse();

                // 1. Tổng số người dùng (chỉ ROLE_USER)
                Long totalUsers = jdbcTemplate.queryForObject(
                                "SELECT COUNT(*) " +
                                                "FROM users u " +
                                                "JOIN user_role ur ON u.user_id = ur.user_id " +
                                                "JOIN roles r ON r.role_id = ur.role_id " +
                                                "WHERE r.role_name = 'ROLE_USER'",
                                Long.class);
                res.setTotalUsers(totalUsers != null ? totalUsers : 0L);

                // 2. Tổng số báo cáo rác
                Long totalReports = jdbcTemplate.queryForObject(
                                "SELECT COUNT(*) FROM waste_reports",
                                Long.class);
                res.setTotalReports(totalReports != null ? totalReports : 0L);

                // 3. Tổng số chiến dịch môi trường
                Long totalCampaigns = jdbcTemplate.queryForObject(
                                "SELECT COUNT(*) FROM campaigns",
                                Long.class);
                res.setTotalCampaigns(totalCampaigns != null ? totalCampaigns : 0L);

                // 4. Tổng điểm thưởng (sum points trong user_points)
                Long totalPoints = jdbcTemplate.queryForObject(
                                "SELECT COALESCE(SUM(points),0) FROM user_points",
                                Long.class);
                res.setTotalPoints(totalPoints != null ? totalPoints : 0L);

                // 5. Xu hướng hoạt động (5 tháng gần nhất – xử lý trong buildMonthlyActivity)
                List<MonthlyActivityDto> monthly = buildMonthlyActivity();
                res.setMonthlyActivity(monthly);

                // 5b. TÍNH % TĂNG TRƯỞNG SO VỚI THÁNG TRƯỚC
                if (monthly.size() >= 2) {
                        MonthlyActivityDto prev = monthly.get(monthly.size() - 2); // tháng trước
                        MonthlyActivityDto curr = monthly.get(monthly.size() - 1); // tháng hiện tại

                        res.setUserGrowthPercent(
                                        calcGrowth(prev.getUsers(), curr.getUsers()));
                        res.setReportGrowthPercent(
                                        calcGrowth(prev.getReports(), curr.getReports()));
                        res.setCampaignGrowthPercent(
                                        calcGrowth(prev.getCampaigns(), curr.getCampaigns()));

                        // nếu chưa có dữ liệu điểm theo tháng thì tạm cho 0
                        res.setPointGrowthPercent(0.0);
                } else {
                        res.setUserGrowthPercent(0.0);
                        res.setReportGrowthPercent(0.0);
                        res.setCampaignGrowthPercent(0.0);
                        res.setPointGrowthPercent(0.0);
                }

                // 6. Thống kê trạng thái báo cáo rác
                res.setReportStatus(buildReportStatus());

                // 7. Tham gia chiến dịch theo tháng
                res.setCampaignParticipation(buildCampaignParticipation());

                // 8. Phân bố cấp độ người dùng theo điểm hiện tại
                res.setLevelDistribution(buildLevelDistribution());

                // 9. Hoạt động gần đây lấy từ activity_logs
                res.setRecentActivities(buildRecentActivities());

                return res;
        }

        /**
         * Tính phần trăm tăng trưởng: (curr - prev) / prev * 100
         * prev = 0 thì xử lý riêng để tránh chia cho 0.
         */
        private Double calcGrowth(long prev, long curr) {
                if (prev == 0) {
                        if (curr == 0)
                                return 0.0;
                        return 100.0; // hoặc trả null tuỳ cách bạn muốn hiển thị
                }
                return ((double) (curr - prev) / prev) * 100.0;
        }

        private List<MonthlyActivityDto> buildMonthlyActivity() {
                List<MonthlyActivityDto> list = new ArrayList<>();

                YearMonth current = YearMonth.now();
                // 5 tháng gần nhất: current-4 .. current
                for (int i = 4; i >= 0; i--) {
                        YearMonth ym = current.minusMonths(i);
                        int year = ym.getYear();
                        int month = ym.getMonthValue();

                        Long activeUsers = jdbcTemplate.queryForObject(
                                        "SELECT COUNT(DISTINCT user_id) FROM activity_logs " +
                                                        "WHERE YEAR(created_at) = ? AND MONTH(created_at) = ?",
                                        Long.class, year, month);
                        if (activeUsers == null)
                                activeUsers = 0L;

                        Long monthlyReports = jdbcTemplate.queryForObject(
                                        "SELECT COUNT(*) FROM waste_reports " +
                                                        "WHERE YEAR(created_at) = ? AND MONTH(created_at) = ?",
                                        Long.class, year, month);
                        if (monthlyReports == null)
                                monthlyReports = 0L;

                        Long monthlyCampaigns = jdbcTemplate.queryForObject(
                                        "SELECT COUNT(*) FROM campaigns " +
                                                        "WHERE YEAR(start_date) = ? AND MONTH(start_date) = ?",
                                        Long.class, year, month);
                        if (monthlyCampaigns == null)
                                monthlyCampaigns = 0L;

                        String label = ym.getMonth().getDisplayName(java.time.format.TextStyle.SHORT, java.util.Locale.forLanguageTag("vi-VN"))
                                        + "/" + year;

                        list.add(new MonthlyActivityDto(
                                        label,
                                        activeUsers,
                                        monthlyReports,
                                        monthlyCampaigns));
                }

                return list;
        }

        private Map<String, Long> buildReportStatus() {
                String sql = "SELECT status, COUNT(*) AS cnt " +
                                "FROM waste_reports GROUP BY status";

                Map<String, Long> map = new LinkedHashMap<>();
                jdbcTemplate.query(sql, rs -> {
                        String status = rs.getString("status"); // PENDING, VERIFIED, REJECTED, CLEANED
                        long count = rs.getLong("cnt");
                        map.put(status, count);
                });

                return map;
        }

        private List<DashboardCampaignParticipationDto> buildCampaignParticipation() {
                List<DashboardCampaignParticipationDto> list = new ArrayList<>();
                YearMonth current = YearMonth.now();

                for (int i = 4; i >= 0; i--) {
                        YearMonth ym = current.minusMonths(i);
                        int year = ym.getYear();
                        int month = ym.getMonthValue();

                        Long participants = jdbcTemplate.queryForObject(
                                        "SELECT COUNT(*) FROM campaign_participants " +
                                                        "WHERE YEAR(joined_at) = ? AND MONTH(joined_at) = ?",
                                        Long.class, year, month);

                        list.add(new DashboardCampaignParticipationDto(
                                        ym.getMonth().getDisplayName(java.time.format.TextStyle.SHORT, java.util.Locale.forLanguageTag("vi-VN"))
                                                        + "/" + year,
                                        participants != null ? participants : 0L));
                }

                return list;
        }

        private List<DashboardLevelDistributionDto> buildLevelDistribution() {
                String sql = "SELECT " +
                                "SUM(CASE WHEN points < 300 THEN 1 ELSE 0 END) AS bronzeCount, " +
                                "SUM(CASE WHEN points >= 300 AND points < 600 THEN 1 ELSE 0 END) AS silverCount, " +
                                "SUM(CASE WHEN points >= 600 AND points < 900 THEN 1 ELSE 0 END) AS goldCount, " +
                                "SUM(CASE WHEN points >= 900 THEN 1 ELSE 0 END) AS platinumCount " +
                                "FROM user_points";

                Map<String, Object> row = jdbcTemplate.queryForMap(sql);

                return List.of(
                                new DashboardLevelDistributionDto("Bronze", toLong(row.get("bronzeCount"))),
                                new DashboardLevelDistributionDto("Silver", toLong(row.get("silverCount"))),
                                new DashboardLevelDistributionDto("Gold", toLong(row.get("goldCount"))),
                                new DashboardLevelDistributionDto("Platinum", toLong(row.get("platinumCount"))));
        }

        private List<DashboardRecentActivityDto> buildRecentActivities() {
                String sql = "SELECT al.action, al.created_at, u.username " +
                                "FROM activity_logs al " +
                                "JOIN users u ON u.user_id = al.user_id " +
                                "ORDER BY al.created_at DESC, al.log_id DESC " +
                                "LIMIT 4";

                List<DashboardRecentActivityDto> activities = new ArrayList<>();
                jdbcTemplate.query(sql, rs -> {
                        String action = rs.getString("action");
                        String username = rs.getString("username");
                        Timestamp createdAt = rs.getTimestamp("created_at");
                        activities.add(new DashboardRecentActivityDto(
                                        action,
                                        buildActivityTitle(action, username),
                                        createdAt != null ? createdAt.toLocalDateTime().toString() : null));
                });

                return activities;
        }

        private long toLong(Object value) {
                if (value instanceof Number number) {
                        return number.longValue();
                }
                return 0L;
        }

        private String buildActivityTitle(String action, String username) {
                String displayName = (username == null || username.isBlank()) ? "một người dùng" : username;

                return switch (action) {
                        case "CREATE_REPORT" -> "Người dùng " + displayName + " vừa tạo báo cáo rác mới";
                        case "JOIN_CAMPAIGN" -> "Người dùng " + displayName + " vừa tham gia chiến dịch";
                        case "COMPLETE_QUIZ" -> "Người dùng " + displayName + " vừa hoàn thành quiz";
                        case "REDEEM_COUPON" -> "Người dùng " + displayName + " vừa đổi voucher";
                        case "UPDATE_PROFILE" -> "Người dùng " + displayName + " vừa cập nhật hồ sơ";
                        default -> "Người dùng " + displayName + " vừa thực hiện hoạt động hệ thống";
                };
        }
}
