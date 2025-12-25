package capstone_1.Ecotrack_backend.security;

import capstone_1.Ecotrack_backend.model.User;
import io.jsonwebtoken.*;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.security.Key;
import java.util.Date;
import java.util.List;

@Component
public class JwtUtil {

    private final Key key;
    private final long jwtExpirationMs;

    public JwtUtil(@Value("${app.jwt.secret}") String secret,
                   @Value("${app.jwt.expiration-ms}") long jwtExpirationMs) {
        this.key = Keys.hmacShaKeyFor(secret.getBytes());
        this.jwtExpirationMs = jwtExpirationMs;
    }

    public String generateToken(User user) {
        Date now = new Date();
        Date expiry = new Date(now.getTime() + jwtExpirationMs);
        List<String> roles = user.getRoles().stream()
                .map(role -> role.getName())
                .toList();
        // 2. Tạo Claims và thêm Roles vào
        Claims claims = Jwts.claims().setSubject(user.getUsername());
        claims.put("roles", roles); // <<< ĐÂY LÀ DÒNG QUAN TRỌNG

        return Jwts.builder()
                .setClaims(claims)
                .setIssuedAt(now)
                .setExpiration(expiry)
                .signWith(key, SignatureAlgorithm.HS256)
                .compact();
    }

    public String getUsernameFromToken(String token) {
        try {
            return Jwts.parserBuilder()
                    .setSigningKey(key)
                    .build()
                    .parseClaimsJws(token)
                    .getBody()
                    .getSubject();
        } catch (JwtException e) {
            System.err.println(" Invalid JWT token: " + e.getMessage());
            return null;
        }
    }

    public boolean validateJwtToken(String token) {
        try {
            Jwts.parserBuilder().setSigningKey(key).build().parseClaimsJws(token);
            return true;
        } catch (JwtException e) {
            System.err.println(" Token validation failed: " + e.getMessage());
            return false;
        }
    }

    public Date getIssuedAtFromToken(String token) {
        try {
            Claims claims = Jwts.parserBuilder()
                    .setSigningKey(key)
                    .build()
                    .parseClaimsJws(token)
                    .getBody();
            return claims.getIssuedAt();
        } catch (JwtException e) {
            System.err.println(" Error getting issued at from token: " + e.getMessage());
            return null;
        }
    }
}
