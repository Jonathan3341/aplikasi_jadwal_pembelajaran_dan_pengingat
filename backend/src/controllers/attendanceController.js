
const db = require('../config/database');

const CAMPUS_LATITUDE = -6.1690517;
const CAMPUS_LONGITUDE = 106.7903548 ;

const ATTENDANCE_RADIUS = 100;
const MAX_GPS_ACCURACY = 50;
const WINDOW_MINUTES = 30;

const DAY_MAPPING = {
  Mon: 1,
  Tue: 2,
  Wed: 3,
  Thu: 4,
  Fri: 5,
  Sat: 6,
  Sun: 7,
};

// Mengambil waktu berdasarkan zona Asia/Jakarta.
function getJakartaTime() {
  const parts = new Intl.DateTimeFormat('en-US', {
    timeZone: 'Asia/Jakarta',
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    weekday: 'short',
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
    hourCycle: 'h23',
  }).formatToParts(new Date());

  const values = {};

  for (const part of parts) {
    values[part.type] = part.value;
  }

  return {
    date: `${values.year}-${values.month}-${values.day}`,
    weekday: DAY_MAPPING[values.weekday],
    hour: Number(values.hour),
    minute: Number(values.minute),
    second: Number(values.second),
  };
}

function toMinutes(time) {
  const [hour, minute] = time.split(':').map(Number);
  return hour * 60 + minute;
}

function getCurrentMinutes(time) {
  return time.hour * 60 + time.minute;
}

// Menghitung jarak menggunakan rumus Haversine.
function calculateDistance(lat1, lon1, lat2, lon2) {
  const earthRadius = 6371000;

  const toRadians = (degree) => degree * Math.PI / 180;

  const dLat = toRadians(lat2 - lat1);
  const dLon = toRadians(lon2 - lon1);

  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRadians(lat1)) *
    Math.cos(toRadians(lat2)) *
    Math.sin(dLon / 2) ** 2;

  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

  return earthRadius * c;
}

// Mengambil jadwal dan status absensi hari ini.
function getAvailableAttendance(req, res) {
  const student = db.prepare(`
    SELECT id, class_id
    FROM users
    WHERE id = ? AND role = 'Murid'
  `).get(req.user.id);

  if (!student || !student.class_id) {
    return res.status(400).json({
      message: 'Data kelas mahasiswa tidak ditemukan.',
    });
  }

  const now = getJakartaTime();

  const schedules = db.prepare(`
    SELECT
      id,
      subject,
      weekday,
      start_time,
      end_time,
      room,
      lecturer
    FROM schedules
    WHERE class_id = ?
      AND weekday = ?
    ORDER BY start_time ASC
  `).all(student.class_id, now.weekday);

  const findAttendance = db.prepare(`
    SELECT id, status, check_in_at
    FROM attendance_records
    WHERE schedule_id = ?
      AND student_id = ?
      AND attendance_date = ?
  `);

  const currentMinutes = getCurrentMinutes(now);

  const result = schedules.map((schedule) => {
    const startMinutes = toMinutes(schedule.start_time);

    const opensAt = startMinutes - WINDOW_MINUTES;
    const closesAt = startMinutes + WINDOW_MINUTES;

    const attendance = findAttendance.get(
      schedule.id,
      student.id,
      now.date
    );

    let state = 'Belum Dibuka';

    if (currentMinutes >= opensAt && currentMinutes <= closesAt) {
      state = 'Dibuka';
    } else if (currentMinutes > closesAt) {
      state = 'Ditutup';
    }

    return {
      ...schedule,
      window_opens_at: `${String(Math.floor(opensAt / 60)).padStart(2, '0')}:${String(opensAt % 60).padStart(2, '0')}`,
      window_closes_at: `${String(Math.floor(closesAt / 60)).padStart(2, '0')}:${String(closesAt % 60).padStart(2, '0')}`,
      can_attend: state === 'Dibuka' && !attendance,
      attendance_state: attendance ? 'Sudah Absen' : state,
      attendance_status: attendance?.status ?? null,
      check_in_at: attendance?.check_in_at ?? null,
    };
  });

  return res.json({
    date: now.date,
    timezone: 'Asia/Jakarta',
    campus: {
      latitude: CAMPUS_LATITUDE,
      longitude: CAMPUS_LONGITUDE,
      radius: ATTENDANCE_RADIUS,
    },
    schedules: result,
  });
}

// Menyimpan absensi mahasiswa.
function submitAttendance(req, res) {
  const { schedule_id, latitude, longitude, accuracy } = req.body;

  if (
    !Number.isInteger(Number(schedule_id)) ||
    latitude === undefined ||
    longitude === undefined ||
    accuracy === undefined
  ) {
    return res.status(400).json({
      message: 'Data absensi tidak lengkap.',
    });
  }

  const lat = Number(latitude);
  const lon = Number(longitude);
  const gpsAccuracy = Number(accuracy);
  const scheduleId = Number(schedule_id);

  if (
    !Number.isFinite(lat) ||
    !Number.isFinite(lon) ||
    !Number.isFinite(gpsAccuracy) ||
    lat < -90 ||
    lat > 90 ||
    lon < -180 ||
    lon > 180 ||
    gpsAccuracy < 0
  ) {
    return res.status(400).json({
      message: 'Koordinat atau akurasi GPS tidak valid.',
    });
  }

  if (gpsAccuracy > MAX_GPS_ACCURACY) {
    return res.status(400).json({
      message: `Akurasi GPS terlalu rendah. Maksimal ${MAX_GPS_ACCURACY} meter.`,
      accuracy: gpsAccuracy,
    });
  }

  const student = db.prepare(`
    SELECT id, class_id
    FROM users
    WHERE id = ? AND role = 'Murid'
  `).get(req.user.id);

  if (!student || !student.class_id) {
    return res.status(400).json({
      message: 'Data kelas mahasiswa tidak ditemukan.',
    });
  }

  const schedule = db.prepare(`
    SELECT id, class_id, subject, weekday, start_time, end_time
    FROM schedules
    WHERE id = ? AND class_id = ?
  `).get(scheduleId, student.class_id);

  if (!schedule) {
    return res.status(403).json({
      message: 'Jadwal tidak ditemukan atau bukan milik kelas Anda.',
    });
  }

  const now = getJakartaTime();

  if (schedule.weekday !== now.weekday) {
    return res.status(400).json({
      message: 'Jadwal ini bukan jadwal perkuliahan hari ini.',
    });
  }

  const currentMinutes = getCurrentMinutes(now);
  const startMinutes = toMinutes(schedule.start_time);

  const opensAt = startMinutes - WINDOW_MINUTES;
  const closesAt = startMinutes + WINDOW_MINUTES;

  if (currentMinutes < opensAt) {
    return res.status(400).json({
      message: `Absensi belum dibuka. Absensi dibuka pukul ${String(Math.floor(opensAt / 60)).padStart(2, '0')}:${String(opensAt % 60).padStart(2, '0')}.`,
    });
  }

  if (currentMinutes > closesAt) {
    return res.status(400).json({
      message: 'Waktu absensi sudah ditutup.',
    });
  }

  const distance = calculateDistance(
    lat,
    lon,
    CAMPUS_LATITUDE,
    CAMPUS_LONGITUDE
  );

  if (distance > ATTENDANCE_RADIUS) {
    return res.status(400).json({
      message: 'Anda berada di luar radius lokasi kampus.',
      distance: Number(distance.toFixed(2)),
      allowed_radius: ATTENDANCE_RADIUS,
    });
  }

  const status =
    currentMinutes < startMinutes ? 'Hadir' : 'Terlambat';

  const checkInAt = new Date().toISOString();

  try {
    const result = db.prepare(`
      INSERT INTO attendance_records (
        schedule_id,
        student_id,
        attendance_date,
        check_in_at,
        latitude,
        longitude,
        accuracy,
        distance,
        status
      )
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    `).run(
      schedule.id,
      student.id,
      now.date,
      checkInAt,
      lat,
      lon,
      gpsAccuracy,
      Number(distance.toFixed(2)),
      status
    );

    return res.status(201).json({
      message: 'Absensi berhasil disimpan.',
      attendance: {
        id: Number(result.lastInsertRowid),
        schedule_id: schedule.id,
        subject: schedule.subject,
        attendance_date: now.date,
        check_in_at: checkInAt,
        distance: Number(distance.toFixed(2)),
        accuracy: gpsAccuracy,
        status,
      },
    });
  } catch (error) {
    if (
      error.code === 'SQLITE_CONSTRAINT_UNIQUE' ||
      error.code === 'SQLITE_CONSTRAINT_PRIMARYKEY'
    ) {
      return res.status(409).json({
        message: 'Anda sudah melakukan absensi untuk jadwal ini.',
      });
    }

    throw error;
  }
}

// Mengambil riwayat absensi mahasiswa.
function getMyAttendance(req, res) {
  const attendance = db.prepare(`
    SELECT
      ar.id,
      ar.schedule_id,
      ar.attendance_date,
      ar.check_in_at,
      ar.status,
      ar.distance,
      ar.accuracy,
      s.subject,
      s.start_time,
      s.end_time,
      s.room
    FROM attendance_records ar
    JOIN schedules s ON s.id = ar.schedule_id
    WHERE ar.student_id = ?
    ORDER BY ar.attendance_date DESC, ar.check_in_at DESC
  `).all(req.user.id);

  return res.json({
    attendance,
  });
}




// Mengambil rekap keseluruhan absensi Murid.
function getMyAttendanceSummary(req, res) {
  try {
    const student = db.prepare(`
      SELECT id, class_id, role
      FROM users
      WHERE id = ?
    `).get(req.user.id);

    if (!student || student.role !== 'Murid') {
      return res.status(404).json({
        message: 'Data Murid tidak ditemukan.',
      });
    }

    if (!student.class_id) {
      return res.status(400).json({
        message: 'Murid belum ditempatkan ke kelas akademik.',
      });
    }

    const now = getJakartaTime();
    const currentDate = now.date;
    const currentMinutes = getCurrentMinutes(now);

    // Mengambil jadwal kelas beserta tanggal pembuatannya.
    const schedules = db.prepare(`
      SELECT
        id,
        weekday,
        start_time,
        end_time,
        created_at,
        date(created_at, '+7 hours') AS start_date,
        time(created_at, '+7 hours') AS created_time
      FROM schedules
      WHERE class_id = ?
    `).all(student.class_id);

    // Mengambil seluruh riwayat absensi Murid.
    const attendanceRecords = db.prepare(`
      SELECT
        ar.schedule_id,
        ar.attendance_date
      FROM attendance_records ar
      INNER JOIN schedules s
        ON s.id = ar.schedule_id
      WHERE
        ar.student_id = ?
        AND s.class_id = ?
    `).all(student.id, student.class_id);

    const attendanceSet = new Set(
      attendanceRecords.map(
        (item) => `${item.schedule_id}_${item.attendance_date}`
      )
    );

    let presentCount = 0;
    let absentCount = 0;

    for (const schedule of schedules) {
      if (!schedule.start_date) continue;

      if (schedule.start_date > currentDate) continue;

      const startDate = new Date(
        `${schedule.start_date}T00:00:00.000Z`
      );

      const endDate = new Date(
        `${currentDate}T00:00:00.000Z`
      );

      for (
        let date = new Date(startDate);
        date <= endDate;
        date.setUTCDate(date.getUTCDate() + 1)
      ) {
        const weekday = date.getUTCDay() || 7;

        if (weekday !== schedule.weekday) {
          continue;
        }

        const attendanceDate = date.toISOString().slice(0, 10);

        // Jadwal tidak dihitung sebelum tanggal dibuat.
        if (attendanceDate === schedule.start_date) {
          const createdMinutes = toMinutes(schedule.created_time);

          if (createdMinutes > toMinutes(schedule.start_time)) {
            continue;
          }
        }

        const attendanceKey =
          `${schedule.id}_${attendanceDate}`;

        const hasAttendance = attendanceSet.has(attendanceKey);

        // Jika sudah melakukan absensi, langsung hitung sebagai Hadir.
        if (hasAttendance) {
          presentCount++;
          continue;
        }

        // Jika belum absen, pertemuan hari ini belum dihitung
        // sampai waktu jadwal selesai.
        if (attendanceDate === currentDate) {
          if (currentMinutes < toMinutes(schedule.end_time)) {
            continue;
          }
        }

        // Pertemuan selesai tanpa absensi dihitung Tidak Hadir.
        absentCount++;
      }
    }

    const totalMeetings = presentCount + absentCount;

    return res.json({
      message: 'Rekap absensi berhasil diambil.',
      data: {
        total_meetings: totalMeetings,
        present_count: presentCount,
        absent_count: absentCount,
      },
    });
  } catch (error) {
    console.error('Get attendance summary error:', error);

    return res.status(500).json({
      message: 'Gagal mengambil rekap absensi.',
    });
  }
}

module.exports = {
  getAvailableAttendance,
  submitAttendance,
  getMyAttendance,
  getMyAttendanceSummary,
};
