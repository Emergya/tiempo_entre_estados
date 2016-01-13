class TeeTimetable < ActiveRecord::Base
  unloadable

  has_many :journals, :class_name => 'TeeTimetableJournal', :dependent => :destroy
  has_and_belongs_to_many :roles
  accepts_nested_attributes_for :journals

  validate :avoid_overlap
  validate :check_timetable_default
  validate :check_dates
  validate :check_name_blank
  validate :check_name_uniq
  validate :check_roles
  validate :check_timetable_default_by_role
  before_update :set_timetable_default

  # Genera mensaje de error
  def get_error_message
    error_msg = ""
    
    self.errors.full_messages.each do |msg|
      if error_msg != ""
        error_msg << "<br>"
      end
      error_msg << msg
    end

    error_msg
  end

  # Tiempo trabajado en una semana completa
  def week_total_time
  	journals.inject(0.0){|sum,j| sum + j.day_total_time}
  end

  # Calcula el tiempo trabajado entre dos fechas para este horario
  def get_time(stime, etime)
  	time = 0

  	if etime.to_date == stime.to_date
  	  time += journal(stime).day_time(stime, etime)
  	else
  	  second_day = (stime + 1.day).to_date
  	  penultimate_day = (etime - 1.day).to_date

      # Calculamos el tiempo las semanas completas que hay en el intervalo
  	  weeks = ([(penultimate_day - second_day).to_i + 1, 0].max / 7).floor
  	  time += weeks * week_total_time
      # Para el resto de días, calculamos por cada día
  	  (stime.to_date..(etime - (weeks * 7).days).to_date).each do |date|
  	    case date
	  	  when stime.to_date
	  		time += journal(date).day_time(stime)
	  	  when (etime - (7 * weeks).days).to_date
	  		time += journal(date).day_time(nil, etime)
	  	  else
	  		time += journal(date).day_time
	  	end
	  end
	end

	time
  end

  # Calcula el tiempo en el caso de que en el intervalo sea algún día festivo
  def get_holidays_time(stime, etime, holidays_days)
    time = 0
  
    if !holidays_days.empty?
      i = 0

      until i >= holidays_days.length
        # Se comprueba que para el dia seleccionado se encuentra dentro del rango del intervalo
        if holidays_days[i].to_date >= stime.to_date && holidays_days[i].to_date <= etime.to_date
          
          # Si coincide en el inicio de stime
          if holidays_days[i].to_date == stime.to_date
            stime = stime
            if stime.end_of_day > etime
              interval_time = etime
            else
              interval_time = stime.end_of_day
            end
          # Si coincide con el final de etime
          elsif holidays_days[i].to_date == etime.to_date
            stime = etime.beginning_of_day
            interval_time = etime
          # Si se encuentra dentro del rango
          else
            stime = holidays_days[i].to_date.beginning_of_day
            interval_time = holidays_days[i].to_date.end_of_day
          end

          time += self.get_time(stime, interval_time)
        end
        i += 1
      end

    end

    time
  end

  # Devuelve un array con todos los días festivos de un perfil
  def self.get_holidays_days(holidays)
    days = []

    holidays.each do |holiday|
      days << holiday.date.split(",")
    end

    return days
  end

  # Devuelve el tiempo total para el intervalo indicado
  def self.get_total_time(project_id, role_id, stime, etime)
    time = 0

    holidays_days = []
    holidays = TeeHoliday.joins(:roles).where("roles.id = ?", role_id)
    if !holidays.empty?
      holidays_days << self.get_holidays_days(holidays)
      holidays_days = holidays_days.flatten.sort
    end

      while stime < etime 

        timetable = TeeTimetable.joins(:roles).where("project_id = ? AND roles.id = ? AND start_date <= ? AND end_date > ? AND tee_timetables.default = 0", project_id, role_id, etime, stime).order(:stime => :desc).first
        
        if timetable.present? and timetable.start_date <= stime
          interval_etime = [timetable.end_date, etime].min
        else
          if timetable.present?
            interval_etime = timetable.start_date
          else
            interval_etime = etime
          end

          timetable = TeeTimetable.joins(:roles).where("project_id = ? AND roles.id = ? AND tee_timetables.default = 1", project_id, role_id).first
        end

        if timetable.present?   
          time += timetable.get_time(stime, interval_etime)
          time -= timetable.get_holidays_time(stime, interval_etime, holidays_days)
        end

        stime = interval_etime
      end

    time
  end

  def journal(date)
	journals.where("week_day = ?", date.wday).first
  end

  private
    # Valida que no existen solapamientos
    def avoid_overlap
       errors.add :base, l(:"error.timetable_overlap") if TeeTimetable.joins(:roles).where('tee_timetables.id != ? AND roles.id in (?) AND project_id = ? AND (end_date >= ? AND start_date <= ?)', self.id || '', self.roles.map(&:id), self.project_id, self.start_date, self.end_date).present?   
    end
    
    # Valida que si no es un horario por defecto, start_date y end_date tenga una fecha
    def check_timetable_default 
      errors.add :base, l(:"error.check_timetable_default") if self.default == false && self.start_date == nil && self.end_date == nil
    end

    # Valida que la fecha de inicio no es mayor que la fecha de fin
    def check_dates
      errors.add :base, l(:"error.date_error") if (self.start_date != nil && self.end_date != nil) && (self.start_date > self.end_date)
    end

    # Valida que el nombre del horario no este en blanco
    def check_name_blank
      errors.add :base, l(:"error.timetable_name_blank") if self.name.blank?
    end

    # Valida que el nombre del horario no este repetido
    def check_name_uniq
      if self.id != nil
        errors.add :base, l(:"error.timetable_name_uniq") if TeeTimetable.where("name = ? AND id != ?", self.name, self.id).present?
      else
        errors.add :base, l(:"error.timetable_name_uniq") if TeeTimetable.where(name: self.name).present?
      end
    end

    # Valida que se encuentra seleccionado algún rol
    def check_roles
      errors.add :base, l(:"error.timetable_roles_blank") if self.roles.blank?
    end

    # Valida que solo haya un horario por defecto para cada perfil
    def check_timetable_default_by_role
      if self.default == true
        self.roles.each do |role|
          if self.id != nil
            errors.add :base, l(:"error.timetable_default_by_role", name: role.name) if role.tee_timetables.where("tee_timetables.default = ? AND tee_timetables.id != ?", true, self.id).present?
          else
            errors.add :base, l(:"error.timetable_default_by_role", name: role.name) if role.tee_timetables.where(default: true).present?
          end
        end
      end
    end

    # En el caso de que el horario sea por defecto se le asigna el valor null a las fechas de inicio y de fin.
    def set_timetable_default
      if self.default == true
        self.start_date = nil
        self.end_date = nil
      end
    end
end