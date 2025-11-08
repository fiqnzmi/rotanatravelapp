(() => {
  const bell = document.querySelector('[data-notifications="true"]');
  const badge = document.getElementById('notificationBadge');
  const content = document.getElementById('notificationContent');
  const dropdown = document.getElementById('notificationDropdown');
  if (!bell || !badge || !content || !dropdown) {
    return;
  }

  const POLL_INTERVAL_MS = 15000;
  const NOTIFICATIONS_URL = bell.getAttribute('data-notifications-url') || 'notifications.php';

  let lastCount = Number.parseInt(bell.getAttribute('data-initial-count') || '0', 10) || 0;
  let pollingTimer;

  const formatMessage = (item) => {
    const customer = (item.customer_name || '').trim();
    const packageName = (item.package_name || '').trim();
    if (customer && packageName) {
      return `${customer} — ${packageName}`;
    }
    if (packageName) {
      return `${packageName} booking pending`;
    }
    if (customer) {
      return `${customer} booking pending`;
    }
    return 'Incoming Customer Booking (Pending)';
  };

  const formatTime = (isoString) => {
    if (!isoString) return '';
    const dt = new Date(isoString);
    if (Number.isNaN(dt.getTime())) return '';
    return dt.toLocaleString(undefined, {
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    });
  };

  const updateBadge = (count) => {
    badge.textContent = count;
    if (count > 0) {
      badge.classList.remove('d-none');
      bell.dataset.hasNotifications = 'true';
    } else {
      badge.classList.add('d-none');
      bell.dataset.hasNotifications = 'false';
    }
  };

  const renderNotifications = (items) => {
    content.innerHTML = '';
    if (!items || items.length === 0) {
      const empty = document.createElement('div');
      empty.className = 'text-muted small px-1 py-1';
      empty.textContent = 'No new notifications.';
      content.append(empty);
      return;
    }

    const list = document.createElement('ol');
    list.className = 'mb-0 ps-3';

    items.forEach((item) => {
      const li = document.createElement('li');
      const label = formatMessage(item);
      li.textContent = label;

      const timestamp = formatTime(item.created_at);
      if (timestamp) {
        const time = document.createElement('div');
        time.className = 'text-muted small';
        time.textContent = timestamp;
        li.appendChild(time);
      }

      list.appendChild(li);
    });

    content.append(list);
  };

  const fetchNotifications = async () => {
    try {
      const response = await fetch(NOTIFICATIONS_URL, {
        headers: {
          'X-Requested-With': 'XMLHttpRequest',
        },
      });

      if (response.status === 401) {
        stopPolling();
        return;
      }

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}`);
      }

      const payload = await response.json();
      if (!payload || payload.ok !== true) {
        throw new Error('Invalid payload');
      }

      const count = Number.parseInt(payload.pendingCount ?? 0, 10) || 0;
      updateBadge(count);
      renderNotifications(Array.isArray(payload.items) ? payload.items : []);

      if (count > lastCount) {
        bell.classList.add('notif-pulse');
        setTimeout(() => bell.classList.remove('notif-pulse'), 2000);
      }

      lastCount = count;
    } catch (error) {
      console.error('Failed to refresh notifications', error);
    }
  };

  const startPolling = () => {
    if (pollingTimer) return;
    pollingTimer = setInterval(() => {
      if (document.hidden) return;
      fetchNotifications();
    }, POLL_INTERVAL_MS);
  };

  const stopPolling = () => {
    if (pollingTimer) {
      clearInterval(pollingTimer);
      pollingTimer = null;
    }
  };

  bell.addEventListener('shown.bs.dropdown', () => {
    badge.classList.add('d-none');
  });

  document.addEventListener('visibilitychange', () => {
    if (!document.hidden) {
      fetchNotifications();
    }
  });

  fetchNotifications();
  startPolling();
})();
