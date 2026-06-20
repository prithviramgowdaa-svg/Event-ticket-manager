// Vantage Database Client Abstraction connecting to Supabase
(function (global) {
  let supabaseInstance = null;
  let lastAdminPassword = null;
  let lastScannerPassword = null;
  let lastUserEmail = null;

  function getSupabase() {
    const adminPassword = localStorage.getItem('vantage_admin_password') || 'JgiSnpsu';
    const scannerPassword = localStorage.getItem('vantage_scanner_password') || 'YashbotJgi';
    const user = sessionStorage.getItem('vantage_user') ? JSON.parse(sessionStorage.getItem('vantage_user')) : null;
    const userEmail = user ? user.email : '';

    if (!supabaseInstance || 
        adminPassword !== lastAdminPassword || 
        scannerPassword !== lastScannerPassword || 
        userEmail !== lastUserEmail) {
      
      lastAdminPassword = adminPassword;
      lastScannerPassword = scannerPassword;
      lastUserEmail = userEmail;

      supabaseInstance = supabase.createClient(
        'https://ztwqrrawslktvkokkalq.supabase.co',
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inp0d3FycmF3c2xrdHZrb2trYWxxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODAzMTY3OTEsImV4cCI6MjA5NTg5Mjc5MX0.qVYsOL-pSdt77fgg--oKJyQjJSWzaI5RuissFa3eAkw',
        {
          global: {
            headers: {
              'x-admin-password': adminPassword,
              'x-scanner-password': scannerPassword,
              'x-user-email': userEmail
            }
          }
        }
      );
    }
    return supabaseInstance;
  }

  const VantageDB = {
    getSupabaseClient: getSupabase,

    init() {
      console.log("VantageDB initialized with Supabase.");
    },

    async getEvents() {
      const { data, error } = await getSupabase()
        .from('events')
        .select('*');
      if (error) {
        console.error("Error getting events:", error);
        return {};
      }
      const eventsObj = {};
      data.forEach(e => {
        eventsObj[e.id] = {
          id: e.id,
          title: e.title,
          category: e.category,
          date: e.date,
          location: e.location,
          capacity: e.capacity,
          doors: e.doors,
          ageLimit: e.age_limit,
          age_limit: e.age_limit,
          status: e.status,
          image: e.image,
          description: e.description,
          lineupTitle: e.lineup_title,
          lineup_title: e.lineup_title,
          lineup: e.lineup || [],
          tiers: e.tiers || [],
          is_public: e.is_public,
          isPublic: e.is_public,
          is_featured: e.is_featured,
          isFeatured: e.is_featured,
          is_archived: e.is_archived,
          isArchived: e.is_archived,
          booking_start: e.booking_start,
          bookingStart: e.booking_start,
          booking_end: e.booking_end,
          bookingEnd: e.booking_end,
          last_booking_time: e.last_booking_time,
          lastBookingTime: e.last_booking_time,
          created_at: e.created_at
        };
      });
      return eventsObj;
    },

    async getEvent(id) {
      const { data, error } = await getSupabase()
        .from('events')
        .select('*')
        .eq('id', id)
        .maybeSingle();
      if (error || !data) {
        console.error("Error getting event:", error);
        return null;
      }
      return {
        id: data.id,
        title: data.title,
        category: data.category,
        date: data.date,
        location: data.location,
        capacity: data.capacity,
        doors: data.doors,
        ageLimit: data.age_limit,
        age_limit: data.age_limit,
        status: data.status,
        image: data.image,
        description: data.description,
        lineupTitle: data.lineup_title,
        lineup_title: data.lineup_title,
        lineup: data.lineup || [],
        tiers: data.tiers || [],
        is_public: data.is_public,
        isPublic: data.is_public,
        is_featured: data.is_featured,
        isFeatured: data.is_featured,
        is_archived: data.is_archived,
        isArchived: data.is_archived,
        booking_start: data.booking_start,
        bookingStart: data.booking_start,
        booking_end: data.booking_end,
        bookingEnd: data.booking_end,
        last_booking_time: data.last_booking_time,
        lastBookingTime: data.last_booking_time,
        created_at: data.created_at
      };
    },

    async saveEventDetails(updatedEvent) {
      let cap = typeof updatedEvent.capacity === 'string' ? parseInt(updatedEvent.capacity.replace(/,/g, '')) : updatedEvent.capacity;
      if (isNaN(cap)) {
        cap = 0;
      }

      const payload = {
        title: updatedEvent.title,
        category: updatedEvent.category,
        date: updatedEvent.date,
        location: updatedEvent.location,
        capacity: cap,
        doors: updatedEvent.doors,
        age_limit: updatedEvent.ageLimit || updatedEvent.age_limit || 'All Ages',
        status: updatedEvent.status,
        image: updatedEvent.image,
        description: updatedEvent.description,
        lineup_title: updatedEvent.lineupTitle || updatedEvent.lineup_title || '',
        lineup: updatedEvent.lineup,
        tiers: updatedEvent.tiers,
        is_public: updatedEvent.is_public !== undefined ? updatedEvent.is_public : (updatedEvent.isPublic !== undefined ? updatedEvent.isPublic : true),
        is_featured: updatedEvent.is_featured !== undefined ? updatedEvent.is_featured : (updatedEvent.isFeatured !== undefined ? updatedEvent.isFeatured : false),
        is_archived: updatedEvent.is_archived !== undefined ? updatedEvent.is_archived : (updatedEvent.isArchived !== undefined ? updatedEvent.isArchived : false),
        booking_start: updatedEvent.booking_start || updatedEvent.bookingStart || null,
        booking_end: updatedEvent.booking_end || updatedEvent.bookingEnd || null,
        last_booking_time: updatedEvent.last_booking_time || updatedEvent.lastBookingTime || null
      };

      const { error } = await getSupabase()
        .from('events')
        .update(payload)
        .eq('id', updatedEvent.id);

      if (error) {
        console.error("Error saving event details:", error);
        return false;
      }
      return true;
    },

    async getPurchasedTickets() {
      const { data, error } = await getSupabase()
        .from('tickets')
        .select('*')
        .order('purchase_date', { ascending: false });
      if (error) {
        console.error("Error getting tickets:", error);
        return [];
      }
      return data.map(t => ({
        id: t.id,
        eventId: t.event_id,
        eventName: t.event_name,
        attendeeName: t.attendee_name,
        attendeeEmail: t.attendee_email,
        tierName: t.tier_name,
        price: Number(t.price),
        quantity: t.quantity,
        totalPaid: Number(t.total_paid),
        purchaseDate: t.purchase_date,
        status: t.status,
        scanTime: t.scan_time,
        scanGate: t.scan_gate
      }));
    },

    async saveTicket(ticket) {
      const payload = {
        id: ticket.id,
        event_id: ticket.eventId,
        event_name: ticket.eventName,
        attendee_name: ticket.attendeeName,
        attendee_email: ticket.attendeeEmail,
        tier_name: ticket.tierName,
        price: ticket.price,
        quantity: ticket.quantity,
        total_paid: ticket.totalPaid,
        status: ticket.status || 'valid'
      };

      const { error } = await getSupabase()
        .from('tickets')
        .insert([payload]);

      if (error) {
        console.error("Error saving ticket to Supabase:", error);
        throw error;
      }
      return true;
    },

    async getLogs() {
      const { data, error } = await getSupabase()
        .from('logs')
        .select('*')
        .order('timestamp', { ascending: false });
      if (error) {
        console.error("Error getting logs from Supabase:", error);
        return [];
      }
      return data.map(l => ({
        id: l.id,
        type: l.type,
        gate: l.gate,
        ticketId: l.ticket_id,
        attendeeName: l.attendee_name,
        message: l.message,
        timestamp: l.timestamp
      }));
    },

    async addLog(log) {
      const payload = {
        type: log.type,
        gate: log.gate,
        ticket_id: log.ticketId || log.ticket_id,
        attendee_name: log.attendeeName || log.attendee_name,
        message: log.message
      };
      const { error } = await getSupabase()
        .from('logs')
        .insert([payload]);
      if (error) {
        console.error("Error inserting log to Supabase:", error);
      }
    },

    async verifyTicket(ticketId, gate = "Gate 4 - Staff Portal") {
      const cleanId = ticketId.startsWith('#') ? ticketId.slice(1) : ticketId;
      
      const { data: ticket, error: fetchError } = await getSupabase()
        .from('tickets')
        .select('*')
        .eq('id', cleanId)
        .maybeSingle();

      if (fetchError || !ticket) {
        const errorLog = {
          type: "error",
          gate: gate,
          ticket_id: cleanId,
          attendee_name: "Unknown",
          message: "Ticket ID Not Found"
        };
        await this.addLog(errorLog);
        return { success: false, code: "TKT_NOT_FOUND", message: "Ticket ID Not Found" };
      }

      if (ticket.status === "scanned") {
        const errorLog = {
          type: "error",
          gate: gate,
          ticket_id: ticket.id,
          attendee_name: ticket.attendee_name,
          message: "Duplicate ID Detected"
        };
        await this.addLog(errorLog);
        return {
          success: false,
          code: "TKT_ALREADY_USED",
          message: `Already scanned at ${new Date(ticket.scan_time).toLocaleTimeString()} at ${ticket.scan_gate}`,
          ticket: {
            id: ticket.id,
            eventId: ticket.event_id,
            eventName: ticket.event_name,
            attendeeName: ticket.attendee_name,
            attendeeEmail: ticket.attendee_email,
            tierName: ticket.tier_name,
            price: Number(ticket.price),
            quantity: ticket.quantity,
            totalPaid: Number(ticket.total_paid),
            purchaseDate: ticket.purchase_date,
            status: ticket.status,
            scanTime: ticket.scan_time,
            scanGate: ticket.scan_gate
          }
        };
      }

      const scanTime = new Date().toISOString();
      const { error: updateError } = await getSupabase()
        .from('tickets')
        .update({
          status: 'scanned',
          scan_time: scanTime,
          scan_gate: gate
        })
        .eq('id', cleanId);

      if (updateError) {
        console.error("Error updating ticket scan status:", updateError);
        return { success: false, code: "TKT_UPDATE_FAILED", message: "Failed to update scan status" };
      }

      const successLog = {
        type: "success",
        gate: gate,
        ticket_id: ticket.id,
        attendee_name: ticket.attendee_name,
        message: `Checked in successfully at ${gate}`
      };
      await this.addLog(successLog);

      return {
        success: true,
        ticket: {
          id: ticket.id,
          eventId: ticket.event_id,
          eventName: ticket.event_name,
          attendeeName: ticket.attendee_name,
          attendeeEmail: ticket.attendee_email,
          tierName: ticket.tier_name,
          price: Number(ticket.price),
          quantity: ticket.quantity,
          totalPaid: Number(ticket.total_paid),
          purchaseDate: ticket.purchase_date,
          status: 'scanned',
          scanTime: scanTime,
          scanGate: gate
        }
      };
    },

    async getMetrics() {
      const tickets = await this.getPurchasedTickets();
      const currentRevenue = tickets.reduce((sum, t) => sum + t.totalPaid, 0);
      const currentSold = tickets.length;
      const scannedTickets = tickets.filter(t => t.status === "scanned").length;
      const checkInRate = tickets.length > 0 ? (scannedTickets / tickets.length * 100) : 0;
      
      return {
        totalRevenue: currentRevenue,
        ticketsSold: currentSold,
        attendancePercent: checkInRate > 0 ? checkInRate.toFixed(1) : "0.0"
      };
    },

    getCurrentUser() {
      const user = sessionStorage.getItem("vantage_user");
      return user ? JSON.parse(user) : null;
    },

    loginUser(user) {
      sessionStorage.setItem("vantage_user", JSON.stringify(user));
      window.dispatchEvent(new Event('storage'));
    },

    logoutUser() {
      sessionStorage.removeItem("vantage_user");
      window.dispatchEvent(new Event('storage'));
    },

    async resetDatabase() {
      const supabase = getSupabase();
      
      // 1. Delete all tickets
      const { error: ticketError } = await supabase
        .from('tickets')
        .delete()
        .neq('id', '');
      if (ticketError) console.error("Error clearing tickets:", ticketError);

      // 2. Delete all logs
      const { error: logError } = await supabase
        .from('logs')
        .delete()
        .neq('type', '');
      if (logError) console.error("Error clearing logs:", logError);

      // 3. Reset events to default settings
      const defaultEventTiers = {
        'neon-velocity': [
          {"name": "VIP Experience", "price": 15000, "desc": "Front row access + Lounge", "qtyLeft": 12},
          {"name": "Premium Access", "price": 7500, "desc": "Elevated viewing deck", "qtyLeft": 100},
          {"name": "General Admission", "price": 3500, "desc": "Main arena floor access", "qtyLeft": 250}
        ],
        'neon-eclipse': [
          {"name": "Mainstage Pass", "price": 4999, "desc": "Main arena + Laser show", "qtyLeft": 45},
          {"name": "VIP Backstage", "price": 12500, "desc": "Artist meet & greet", "qtyLeft": 5}
        ],
        'silicon-horizon': [
          {"name": "Conference Pass", "price": 25000, "desc": "Access to all talks & workshops", "qtyLeft": 80},
          {"name": "All-Access VIP", "price": 50000, "desc": "Executive dinners + Private lounge", "qtyLeft": 10}
        ],
        'echoes-in-rain': [
          {"name": "Book Ticket", "price": 2000, "desc": "General Pass", "qtyLeft": 150}
        ],
        'digital-canvas': [
          {"name": "Book Ticket", "price": 1500, "desc": "Expo access", "qtyLeft": 60}
        ],
        'midnight-pulse': [
          {"name": "Book Now", "price": 3500, "desc": "General Access", "qtyLeft": 40}
        ],
        'code-craft': [
          {"name": "Book Now", "price": 7500, "desc": "Full workshop + Kit", "qtyLeft": 15}
        ],
        'elite-gala': [
          {"name": "Book Now", "price": 15000, "desc": "Gala access", "qtyLeft": 20}
        ]
      };

      const { data: events, error: fetchError } = await supabase
        .from('events')
        .select('id, tiers');
      
      if (!fetchError && events) {
        for (const e of events) {
          const tiers = defaultEventTiers[e.id] || e.tiers;
          const isFeatured = (e.id === 'neon-eclipse');
          await supabase
            .from('events')
            .update({
              status: 'active',
              is_public: true,
              is_featured: isFeatured,
              is_archived: false,
              booking_start: null,
              booking_end: null,
              last_booking_time: null,
              tiers: tiers
            })
            .eq('id', e.id);
        }
      }
      return true;
    }
  };

  global.VantageDB = VantageDB;
  VantageDB.init();
})(window);
