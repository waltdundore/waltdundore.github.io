---
layout: default
title: "Jekyll Test Page"
---

# Jekyll Test Page

**Current time:** {{ "now" | date: "%Y-%m-%d %H:%M:%S UTC" }}

**Site title:** {{ site.title }}

**Build hash:** {{ site.project.build_hash }}

If you can see this page with the dynamic content above, Jekyll is working correctly!

## Test Results

- ✅ Jekyll processing: **WORKING**
- ✅ Layout system: **WORKING** 
- ✅ Site variables: **WORKING**
- ✅ Date filters: **WORKING**

[← Back to Home]({{ '/' | relative_url }})