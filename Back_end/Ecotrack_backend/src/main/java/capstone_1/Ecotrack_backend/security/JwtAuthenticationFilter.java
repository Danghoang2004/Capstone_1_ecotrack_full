package capstone_1.Ecotrack_backend.security;

import capstone_1.Ecotrack_backend.model.User;
import capstone_1.Ecotrack_backend.repository.UserRepository;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.web.filter.OncePerRequestFilter;
import java.io.IOException;
import java.util.List;

public class JwtAuthenticationFilter extends OncePerRequestFilter {

    private final JwtUtil jwtUtil;
    private final UserRepository userRepository;

    public JwtAuthenticationFilter(JwtUtil jwtUtil, UserRepository userRepository) {
        this.jwtUtil = jwtUtil;
        this.userRepository = userRepository;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain filterChain)
            throws ServletException, IOException {

        final String authHeader = request.getHeader("Authorization");
        String jwtToken = null;
        String username = null;

        // Nếu không có Authorization → trả 401
        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            filterChain.doFilter(request, response);
            return;
        }
        jwtToken = authHeader.substring(7);
        try {
            username = jwtUtil.getUsernameFromToken(jwtToken);
        } catch (Exception e) {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            return;
        }

        if (username != null && SecurityContextHolder.getContext().getAuthentication() == null) {
            var userOpt = userRepository.findByUsername(username);

            if (userOpt.isEmpty() || !jwtUtil.validateJwtToken(jwtToken)) {
                response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
                return;
            }

            var user = userOpt.get();

            List<SimpleGrantedAuthority> authorities = user.getRoles()
                    .stream()
                    // Chỉ cần lấy tên Role (đã có ROLE_ sẵn trong DB)
                    .map(role -> new SimpleGrantedAuthority(role.getName()))
                    .toList();

            UsernamePasswordAuthenticationToken authToken =
                    new UsernamePasswordAuthenticationToken(
                            user,
                            null,
                            authorities
                    );

            authToken.setDetails(new WebAuthenticationDetailsSource().buildDetails(request));
            SecurityContextHolder.getContext().setAuthentication(authToken);

            request.setAttribute("userId", user.getId());
        }

        filterChain.doFilter(request, response);
    }


}
