---
layout: default
title: "Infrastructure Automation for Schools & Non-Profits"
description: "Simple, transparent infrastructure automation for K-12 schools and non-profits. Deploy services with one command. Built with AI, tested in homelabs, designed for education."
nav_id: "home"
breadcrumb: false
---

<section class="hero">
    <div class="logo-container">
        <img src="{{ '/images/ahab-logo.png' | relative_url }}" alt="Ahab Logo" class="logo">
    </div>
    <h1 class="tagline">Infrastructure Automation for Schools</h1>
    <p class="subtitle">Simple commands. Transparent code. Built for education.</p>
    <div class="hero-cta">
        <a href="#quickstart" class="btn btn-primary">Get Started</a>
        <a href="https://github.com/waltdundore/ahab" target="_blank" class="btn btn-secondary">
            <i class="fab fa-github"></i> View on GitHub
        </a>
    </div>
</section>

<section id="quickstart" class="tutorial-section">
    <h2><i class="fas fa-rocket"></i> Quick Start</h2>
    <div class="card">
        <h3>Deploy a Complete Web Server in 3 Commands</h3>
        <div class="code-block">
            <code>git clone https://github.com/waltdundore/ahab.git</code><br>
            <code>cd ahab && make install</code><br>
            <code>make install apache</code>
        </div>
        <p><strong>That's it!</strong> You now have a Fedora 43 VM with Apache, Docker, and security hardening.</p>
    </div>
    
    <div class="info-box">
        <h4><i class="fas fa-info-circle"></i> What You Get</h4>
        <ul>
            <li>✓ Fedora 43 VM (or Debian/Ubuntu if configured)</li>
            <li>✓ Docker & Docker Compose</li>
            <li>✓ Apache web server with security hardening</li>
            <li>✓ Ansible automation tools</li>
            <li>✓ SELinux/AppArmor security policies</li>
            <li>✓ Firewall configuration</li>
        </ul>
    </div>
</section>

<section class="tutorial-section">
    <h2><i class="fas fa-graduation-cap"></i> Built for Education</h2>
    <div class="feature-grid">
        <div class="feature-card">
            <i class="fas fa-eye"></i>
            <h3>Transparent</h3>
            <p>Every command shows what it's doing. Students see real infrastructure tools in action.</p>
        </div>
        <div class="feature-card">
            <i class="fas fa-shield-alt"></i>
            <h3>Secure by Default</h3>
            <p>Zero Trust development. CIA Triad enforcement. Docker STIG compliance. Built-in security.</p>
        </div>
        <div class="feature-card">
            <i class="fas fa-puzzle-piece"></i>
            <h3>Modular</h3>
            <p>Add services one at a time. Apache, MySQL, PHP, Nginx. Each module is independent.</p>
        </div>
        <div class="feature-card">
            <i class="fas fa-laptop-code"></i>
            <h3>Real Tools</h3>
            <p>Same tools used by Netflix, Spotify, and major tech companies. Industry-standard skills.</p>
        </div>
    </div>
</section>

<section class="tutorial-section">
    <h2><i class="fas fa-users"></i> Who It's For</h2>
    <div class="audience-grid">
        <div class="audience-card">
            <i class="fas fa-chalkboard-teacher"></i>
            <h3>K-12 Educators</h3>
            <p>Teach infrastructure concepts with hands-on labs. Aligned with Georgia CS standards.</p>
            <a href="{{ '/teachers.html' | relative_url }}" class="btn btn-outline">For Teachers →</a>
        </div>
        <div class="audience-card">
            <i class="fas fa-user-graduate"></i>
            <h3>Students</h3>
            <p>Learn by doing. Deploy real services. Understand how the internet works.</p>
            <a href="{{ '/tutorial.html' | relative_url }}" class="btn btn-outline">Start Tutorial →</a>
        </div>
        <div class="audience-card">
            <i class="fas fa-heart"></i>
            <h3>Non-Profits</h3>
            <p>Deploy infrastructure without expensive consultants. Open source and free.</p>
            <a href="{{ '/learn.html' | relative_url }}" class="btn btn-outline">Learn More →</a>
        </div>
    </div>
</section>

<section class="tutorial-section">
    <h2><i class="fas fa-chart-line"></i> Current Status</h2>
    <div class="status-overview">
        <div class="status-card">
            <i class="fas fa-code-branch"></i>
            <h3>Version {{ site.project.version }}</h3>
            <p>Alpha development - educational use ready</p>
        </div>
        <div class="status-card">
            <i class="fas fa-check-circle"></i>
            <h3>Apache Module</h3>
            <p>Complete with Docker Compose generation</p>
        </div>
        <div class="status-card">
            <i class="fas fa-clock"></i>
            <h3>MySQL & PHP</h3>
            <p>In development - coming Q1 2026</p>
        </div>
    </div>
    <div class="status-cta">
        <a href="{{ '/status.html' | relative_url }}" class="btn btn-primary">
            <i class="fas fa-chart-line"></i> View Detailed Status
        </a>
    </div>
</section>